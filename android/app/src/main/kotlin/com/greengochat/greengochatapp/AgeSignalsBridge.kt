package com.greengochat.greengochatapp

import android.app.Activity
import com.google.android.play.agesignals.AgeSignalsAccessRequest
import com.google.android.play.agesignals.AgeSignalsException
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import com.google.android.play.agesignals.model.AgeSignalsStatus
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * P3-1 regional age assurance: Google Play Age Signals API (beta, 0.0.4).
 *
 * Channel `com.greengochat.greengochatapp/age_signals`, method
 * `checkAgeSignals` -> map:
 *   available       false when Play / the API cannot answer (then the app
 *                   offers ID verification instead)
 *   shared          whether the user shared an age signal with the app
 *   status          AgeSignalsStatus (1 SHARED, 2 NOT_SHARED, 3 VERIFICATION_REQUIRED)
 *   ageLower/ageUpper  age band (ageUpper null for the top band, e.g. 18+)
 *   ageRangeSource  1 TIER_A self-declared, 2 TIER_B guardian, 3 TIER_C
 *                   card/email/selfie/ID/tax ID, 4 TIER_D ID + selfie or digital ID
 *   installId       Play install id
 *
 * The values are only READ here. The app sends them to the
 * `recordStoreAgeSignal` callable, which decides whether they are strong
 * enough. The API has no server-verifiable signed token: a modified client can
 * forge the map, which is why a store signal only ever counts as the
 * `store_signal` method server-side.
 */
class AgeSignalsBridge(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.greengochat.greengochatapp/age_signals"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "checkAgeSignals") {
            result.notImplemented()
            return
        }
        // Reply exactly once, whatever the Play callbacks do.
        var replied = false
        fun reply(value: Map<String, Any?>) {
            if (replied) return
            replied = true
            result.success(value)
        }
        fun unavailable(e: Exception?) = reply(
            mapOf(
                "available" to false,
                "errorCode" to ((e as? AgeSignalsException)?.errorCode),
                "error" to (e?.javaClass?.simpleName ?: "unknown"),
            )
        )

        val manager = try {
            AgeSignalsManagerFactory.create(activity.applicationContext)
        } catch (e: Exception) {
            unavailable(e)
            return
        }

        try {
            manager.requestAgeSignalsAccess(
                AgeSignalsAccessRequest.builder().setActivity(activity).build()
            ).addOnSuccessListener { access ->
                val status = access.ageSignalsStatus()
                if (status != AgeSignalsStatus.SHARED) {
                    reply(mapOf("available" to true, "shared" to false, "status" to status))
                    return@addOnSuccessListener
                }
                manager.checkAgeSignals(AgeSignalsRequest.builder().build())
                    .addOnSuccessListener { r ->
                        reply(
                            mapOf(
                                "available" to true,
                                "shared" to true,
                                "status" to status,
                                "ageLower" to r.ageLower(),
                                "ageUpper" to r.ageUpper(),
                                "ageRangeSource" to r.ageRangeSource(),
                                "installId" to r.installId(),
                            )
                        )
                    }
                    .addOnFailureListener { e -> unavailable(e) }
            }.addOnFailureListener { e -> unavailable(e) }
        } catch (e: Exception) {
            unavailable(e)
        }
    }
}
