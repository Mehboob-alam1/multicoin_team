package com.crypto.blockchain.mining.tycoon

import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class MediumNativeAdFactory(
    private val inflater: LayoutInflater,
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = inflater.inflate(R.layout.native_ad_medium, null) as NativeAdView

        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        (adView.headlineView as TextView).text = nativeAd.headline
        adView.mediaView?.mediaContent = nativeAd.mediaContent

        val body = adView.bodyView as TextView
        if (nativeAd.body.isNullOrEmpty()) {
            body.visibility = android.view.View.GONE
        } else {
            body.visibility = android.view.View.VISIBLE
            body.text = nativeAd.body
        }

        val cta = adView.callToActionView as Button
        if (nativeAd.callToAction.isNullOrEmpty()) {
            cta.visibility = android.view.View.GONE
        } else {
            cta.visibility = android.view.View.VISIBLE
            cta.text = nativeAd.callToAction
        }

        val iconView = adView.iconView as ImageView
        val icon = nativeAd.icon
        if (icon == null) {
            iconView.visibility = android.view.View.GONE
        } else {
            iconView.visibility = android.view.View.VISIBLE
            iconView.setImageDrawable(icon.drawable)
        }

        val advertiser = adView.advertiserView as TextView
        if (nativeAd.advertiser.isNullOrEmpty()) {
            advertiser.visibility = android.view.View.GONE
        } else {
            advertiser.visibility = android.view.View.VISIBLE
            advertiser.text = nativeAd.advertiser
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
