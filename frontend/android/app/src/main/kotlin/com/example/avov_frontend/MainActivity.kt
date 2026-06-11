package com.example.avov_frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
    // TextureView evita fallos de Gralloc/SurfaceView en Xiaomi/MIUI.
    override fun getRenderMode(): RenderMode = RenderMode.texture
}
