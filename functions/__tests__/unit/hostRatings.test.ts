/**
 * Host overall rating (profiles/{hostId}.hostRating*) — pure aggregate math.
 * Simulates the trigger pipeline: every review write applies its delta to the
 * experience AND the host; deleting an experience subtracts its aggregate; the
 * review deletes that follow find the experience gone and change nothing.
 */
import {
  computeAggregateDelta,
  applyAggregateDelta,
  applyHostRatingDelta,
  experienceHostContribution,
  hostDeltaFromAggregateDelta,
  negateHostDelta,
  isZeroHostDelta,
  RatingAggregate,
  HostRatingTotals,
} from '../../src/user_experiences/aggregates';

type Doc = Record<string, unknown> | null;
const v = (rating: number): Doc => ({ status: 'visible', rating });
const rej = (rating: number): Doc => ({ status: 'rejected', rating });

/** Minimal in-memory model of the experience + host docs the triggers touch. */
class World {
  exps = new Map<string, RatingAggregate & { hostRatingCounted: boolean }>();
  host: HostRatingTotals | Record<string, never> = {};

  addExp(id: string, counted = true) {
    this.exps.set(id, { ...applyAggregateDelta({}, { sum: 0, count: 0, dist: {} }), hostRatingCounted: counted });
  }
  /** onExperienceReviewWritten, aggregate part. */
  review(expId: string, before: Doc, after: Doc) {
    const exp = this.exps.get(expId);
    if (!exp) return; // experience deleted: nothing changes
    const d = computeAggregateDelta(before, after);
    this.exps.set(expId, { ...applyAggregateDelta(exp as any, d), hostRatingCounted: exp.hostRatingCounted });
    if (exp.hostRatingCounted) {
      this.host = applyHostRatingDelta(this.host as any, hostDeltaFromAggregateDelta(d));
    }
  }
  /** onUserExperienceWritten delete branch. */
  deleteExp(expId: string) {
    const before = this.exps.get(expId);
    this.exps.delete(expId);
    if (before?.hostRatingCounted) {
      this.host = applyHostRatingDelta(this.host as any, negateHostDelta(experienceHostContribution(before as any)));
    }
  }
  /** backfillHostRatings, one experience. */
  backfill(expId: string) {
    const exp = this.exps.get(expId);
    if (!exp || exp.hostRatingCounted) return;
    this.host = applyHostRatingDelta(this.host as any, experienceHostContribution(exp as any));
    exp.hostRatingCounted = true;
  }
}

describe('host rating totals', () => {
  it('sums visible reviews across all of the host experiences', () => {
    const w = new World();
    w.addExp('a');
    w.addExp('b');
    w.review('a', null, v(5));
    w.review('a', null, v(4));
    w.review('b', null, v(3));
    w.review('b', null, rej(1)); // rejected never counts
    expect(w.host).toEqual({ hostRatingSum: 12, hostRatingCount: 3, hostRatingAvg: 4 });
  });

  it('rating change moves the sum, not the count', () => {
    const w = new World();
    w.addExp('a');
    w.review('a', null, v(2));
    w.review('a', v(2), v(5));
    expect(w.host).toEqual({ hostRatingSum: 5, hostRatingCount: 1, hostRatingAvg: 5 });
  });

  it('visible -> rejected removes the review; rejected -> visible adds it back', () => {
    const w = new World();
    w.addExp('a');
    w.review('a', null, v(4));
    w.review('a', null, v(2));
    w.review('a', v(4), rej(4));
    expect(w.host).toEqual({ hostRatingSum: 2, hostRatingCount: 1, hostRatingAvg: 2 });
    w.review('a', rej(4), v(4));
    expect(w.host).toEqual({ hostRatingSum: 6, hostRatingCount: 2, hostRatingAvg: 3 });
  });

  it('review delete decrements; a rejected review delete changes nothing', () => {
    const w = new World();
    w.addExp('a');
    w.review('a', null, v(5));
    w.review('a', null, rej(1));
    w.review('a', rej(1), null);
    expect(w.host).toEqual({ hostRatingSum: 5, hostRatingCount: 1, hostRatingAvg: 5 });
    w.review('a', v(5), null);
    expect(w.host).toEqual({ hostRatingSum: 0, hostRatingCount: 0, hostRatingAvg: 0 });
  });

  it('experience delete subtracts once; its cascaded review deletes do nothing', () => {
    const w = new World();
    w.addExp('a');
    w.addExp('b');
    w.review('a', null, v(5));
    w.review('a', null, v(5));
    w.review('b', null, v(2));
    w.deleteExp('a');
    // recursiveDelete fires review deletes after the experience is gone
    w.review('a', v(5), null);
    w.review('a', v(5), null);
    expect(w.host).toEqual({ hostRatingSum: 2, hostRatingCount: 1, hostRatingAvg: 2 });
  });

  it('uncounted (legacy) experiences only reach the host via backfill, exactly once', () => {
    const w = new World();
    w.addExp('old', false);
    w.addExp('new');
    w.review('old', null, v(4));
    w.review('new', null, v(2));
    expect(w.host).toEqual({ hostRatingSum: 2, hostRatingCount: 1, hostRatingAvg: 2 });
    w.backfill('old');
    w.backfill('old'); // re-run is a no-op
    expect(w.host).toEqual({ hostRatingSum: 6, hostRatingCount: 2, hostRatingAvg: 3 });
    w.review('old', null, v(5)); // now counted live
    expect(w.host).toEqual({ hostRatingSum: 11, hostRatingCount: 3, hostRatingAvg: 3.67 });
    // deleting an uncounted experience never touches the host
    w.addExp('legacy2', false);
    w.review('legacy2', null, v(1));
    w.deleteExp('legacy2');
    expect(w.host).toEqual({ hostRatingSum: 11, hostRatingCount: 3, hostRatingAvg: 3.67 });
  });

  it('never goes below zero on a drifted profile', () => {
    expect(applyHostRatingDelta({ hostRatingSum: 3, hostRatingCount: 1 }, { sum: -10, count: -4 }))
      .toEqual({ hostRatingSum: 0, hostRatingCount: 0, hostRatingAvg: 0 });
    expect(applyHostRatingDelta({ hostRatingSum: 1, hostRatingCount: 3 }, { sum: -5, count: -1 }))
      .toEqual({ hostRatingSum: 0, hostRatingCount: 2, hostRatingAvg: 0 });
    expect(applyHostRatingDelta(null, { sum: 4, count: 1 }))
      .toEqual({ hostRatingSum: 4, hostRatingCount: 1, hostRatingAvg: 4 });
    expect(applyHostRatingDelta({ hostRatingSum: 'x', hostRatingCount: NaN }, { sum: 0, count: 0 }))
      .toEqual({ hostRatingSum: 0, hostRatingCount: 0, hostRatingAvg: 0 });
  });

  it('experience contribution reads its aggregate safely', () => {
    expect(experienceHostContribution({ ratingSum: 9, ratingCount: 2 })).toEqual({ sum: 9, count: 2 });
    expect(experienceHostContribution({ ratingSum: 9, ratingCount: 0 })).toEqual({ sum: 0, count: 0 });
    expect(experienceHostContribution(undefined)).toEqual({ sum: 0, count: 0 });
    expect(isZeroHostDelta(negateHostDelta({ sum: 0, count: 0 }))).toBe(true);
  });
});
