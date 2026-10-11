package com.we46.parkpin

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 12+: fade the system launch screen out instead of cutting it,
        // so it blends into the D01 splash, which starts with the same colour
        // and the same pin in the same place.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.animate()
                    .alpha(0f)
                    .setDuration(250L)
                    .withEndAction { view.remove() }
                    .start()
            }
        }
    }
}
