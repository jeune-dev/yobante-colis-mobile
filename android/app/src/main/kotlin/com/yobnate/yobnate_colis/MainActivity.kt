package com.yobnate.yobnate_colis

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // VULN-H05 : Empêche les captures d'écran et le preview dans le gestionnaire de tâches
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
