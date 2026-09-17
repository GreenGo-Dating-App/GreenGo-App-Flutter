import { brandPush } from '../brand';

describe('brandPush', () => {
  it('always titles the notification GreenGo', () => {
    expect(brandPush('anything', 'at all').title).toBe('GreenGo');
    expect(brandPush('', '').title).toBe('GreenGo');
  });

  it('uses the message wording as-is', () => {
    expect(brandPush('', 'Maria sent you a message.').body)
      .toBe('Maria sent you a message.');
  });

  it('never says the same thing twice', () => {
    // The old join produced "Maria: Maria sent you a message".
    expect(brandPush('Maria', 'Maria sent you a message.').body)
      .toBe('Maria sent you a message.');
    // Case and spacing differences are still duplicates.
    expect(brandPush('New   MESSAGE', 'You have a new message').body)
      .toBe('You have a new message');
    // A title that already contains the body keeps the fuller half.
    expect(brandPush('Event reminder starts soon', 'starts soon').body)
      .toBe('Event reminder starts soon');
  });

  it('keeps both halves when each adds something', () => {
    expect(brandPush('Event reminder', 'Starts at 8pm').body)
      .toBe('Event reminder: Starts at 8pm');
  });

  it('survives an empty half', () => {
    expect(brandPush('Only a title', '').body).toBe('Only a title');
    expect(brandPush('', 'Only a body').body).toBe('Only a body');
    expect(brandPush(undefined, undefined).body).toBe('');
  });

  it('passes an image through, and omits it when absent', () => {
    expect(brandPush('a', 'b', 'https://x/y.png').imageUrl).toBe('https://x/y.png');
    expect('imageUrl' in brandPush('a', 'b')).toBe(false);
  });
});
