/**
 * GreenGo's own push-notification sound (made with the earshot sound bank:
 * three soft mouth / cork pops, no bell). Shipped in the app as
 * android/app/src/main/res/raw/greengo_push.mp3 and ios/Runner/greengo_push.wav.
 *
 * Android locks a channel's sound when the channel is created, so the sound
 * lives on NEW channel ids (created by the app from 5.0.55). An older app that
 * does not have these channels falls back to the manifest default channel
 * (FCM: "if the channel ID provided has not yet been created by the app, FCM
 * uses the channel ID specified in the app manifest") and the default sound;
 * iOS plays the default sound when the file is not in the bundle.
 */
export const PUSH_CHANNEL_ID = 'greengo_push_v2';
export const PUSH_BROADCAST_CHANNEL_ID = 'greengo_broadcasts_v2';
/** Android: raw resource name, no extension. */
export const PUSH_SOUND_ANDROID = 'greengo_push';
/** iOS: file name in the app bundle. */
export const PUSH_SOUND_IOS = 'greengo_push.wav';
