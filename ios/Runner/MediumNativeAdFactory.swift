import google_mobile_ads
import UIKit

class MediumNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> GADNativeAdView? {
    let adView = GADNativeAdView(frame: CGRect(x: 0, y: 0, width: 320, height: 250))
    adView.backgroundColor = UIColor(red: 0.094, green: 0.094, blue: 0.110, alpha: 1)
    adView.clipsToBounds = true

    let badge = UILabel()
    badge.text = "Ad"
    badge.font = UIFont.systemFont(ofSize: 10, weight: .bold)
    badge.textColor = UIColor(red: 0.91, green: 0.84, blue: 1, alpha: 1)
    badge.backgroundColor = UIColor(red: 0.60, green: 0.27, blue: 1, alpha: 0.35)
    badge.textAlignment = .center
    badge.translatesAutoresizingMaskIntoConstraints = false

    let mediaView = GADMediaView()
    mediaView.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFit
    iconView.clipsToBounds = true
    iconView.layer.cornerRadius = 8
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let headline = UILabel()
    headline.font = UIFont.systemFont(ofSize: 14, weight: .bold)
    headline.textColor = .white
    headline.numberOfLines = 2
    headline.translatesAutoresizingMaskIntoConstraints = false

    let advertiser = UILabel()
    advertiser.font = UIFont.systemFont(ofSize: 11, weight: .medium)
    advertiser.textColor = UIColor(white: 0.63, alpha: 1)
    advertiser.translatesAutoresizingMaskIntoConstraints = false

    let body = UILabel()
    body.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    body.textColor = UIColor(white: 0.63, alpha: 1)
    body.numberOfLines = 2
    body.translatesAutoresizingMaskIntoConstraints = false

    let cta = UIButton(type: .system)
    cta.backgroundColor = UIColor(red: 0.60, green: 0.27, blue: 1, alpha: 1)
    cta.setTitleColor(.white, for: .normal)
    cta.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
    cta.layer.cornerRadius = 8
    cta.translatesAutoresizingMaskIntoConstraints = false

    adView.addSubview(badge)
    adView.addSubview(mediaView)
    adView.addSubview(iconView)
    adView.addSubview(headline)
    adView.addSubview(advertiser)
    adView.addSubview(body)
    adView.addSubview(cta)

    NSLayoutConstraint.activate([
      badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 10),
      badge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      badge.widthAnchor.constraint(equalToConstant: 28),
      badge.heightAnchor.constraint(equalToConstant: 16),

      mediaView.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 8),
      mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),
      mediaView.heightAnchor.constraint(equalToConstant: 110),

      iconView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
      iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      iconView.widthAnchor.constraint(equalToConstant: 40),
      iconView.heightAnchor.constraint(equalToConstant: 40),

      headline.topAnchor.constraint(equalTo: iconView.topAnchor),
      headline.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
      headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),

      advertiser.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 2),
      advertiser.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
      advertiser.trailingAnchor.constraint(equalTo: headline.trailingAnchor),

      body.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
      body.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      body.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),

      cta.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 8),
      cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),
      cta.heightAnchor.constraint(equalToConstant: 36),
      cta.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -8),
    ])

    adView.mediaView = mediaView
    adView.headlineView = headline
    adView.bodyView = body
    adView.callToActionView = cta
    adView.iconView = iconView
    adView.advertiserView = advertiser

    headline.text = nativeAd.headline
    mediaView.mediaContent = nativeAd.mediaContent
    body.text = nativeAd.body
    advertiser.text = nativeAd.advertiser
    iconView.image = nativeAd.icon?.image
    cta.setTitle(nativeAd.callToAction, for: .normal)
    adView.nativeAd = nativeAd
    return adView
  }
}
