// MIT License
// Copyright (c) 2023-present Poing Studios

#import "NativeOverlayAd.h"
#import "../helpers/WindowHelper.h"
#import "../PoingGodotAdMobNativeOverlayAd.h"
#import "../helpers/NativeTemplates/GADTMediumTemplateView.h"
#import "../helpers/NativeTemplates/GADTSmallTemplateView.h"

@implementation NativeOverlayAd {
    GADAdLoader *_adLoader;
    GADNativeAd *_nativeAd;
    GADTTemplateView *_templateView;
    NSMutableArray *_activeConstraints;
    int _adPosition;
    int _customX;
    int _customY;
    BOOL _isHidden;
    NSDictionary *_styleDict;
    GADAdSize _customAdSize;
    BOOL _useCustomAdSize;
}

- (instancetype)initWithUID:(NSNumber *)uid {
    if ((self = [super init])) {
        self.UID = uid;
        _activeConstraints = [NSMutableArray array];
        _isHidden = NO;
        _adPosition = 0; // TOP
        _useCustomAdSize = NO;
    }
    return self;
}

- (void)loadWithAdUnitId:(NSString *)adUnitId adRequest:(GADRequest *)adRequest options:(NSDictionary *)optionsDict {
    NSMutableArray *adLoaderOptions = [NSMutableArray array];
    
    GADNativeAdViewAdOptions *adViewOptions = [[GADNativeAdViewAdOptions alloc] init];
    if (optionsDict[@"ad_choices_placement"]) {
        adViewOptions.preferredAdChoicesPosition = (GADAdChoicesPosition)[optionsDict[@"ad_choices_placement"] intValue];
    }
    [adLoaderOptions addObject:adViewOptions];

    GADNativeAdMediaAdLoaderOptions *mediaOptions = [[GADNativeAdMediaAdLoaderOptions alloc] init];
    if (optionsDict[@"media_aspect_ratio"]) {
        mediaOptions.mediaAspectRatio = (GADMediaAspectRatio)[optionsDict[@"media_aspect_ratio"] intValue];
    }
    [adLoaderOptions addObject:mediaOptions];
    
    NSDictionary *videoOptionsDict = optionsDict[@"video_options"];
    if (videoOptionsDict) {
        GADVideoOptions *videoOptions = [[GADVideoOptions alloc] init];
        videoOptions.startMuted = [videoOptionsDict[@"start_muted"] boolValue];
        videoOptions.customControlsRequested = [videoOptionsDict[@"custom_controls_requested"] boolValue];
        videoOptions.clickToExpandRequested = [videoOptionsDict[@"click_to_expand_requested"] boolValue];
        [adLoaderOptions addObject:videoOptions];
    }

    _adLoader = [[GADAdLoader alloc] initWithAdUnitID:adUnitId
                                   rootViewController:[WindowHelper getCurrentRootViewController]
                                              adTypes:@[ GADAdLoaderAdTypeNative ]
                                              options:adLoaderOptions];
    _adLoader.delegate = self;
    [_adLoader loadRequest:adRequest];
}

- (void)renderTemplate:(NSDictionary *)styleDict position:(int)position adSize:(NSDictionary *)adSizeDict {
    _styleDict = styleDict;
    _adPosition = position;
    
    if (adSizeDict && adSizeDict.count > 0) {
        _customAdSize = GADAdSizeFromCGSize(CGSizeMake([adSizeDict[@"width"] floatValue], [adSizeDict[@"height"] floatValue]));
        _useCustomAdSize = YES;
    } else {
        _useCustomAdSize = NO;
    }
    
    [self internalRenderTemplate];
}

- (void)renderTemplateCustomPosition:(NSDictionary *)styleDict x:(int)x y:(int)y adSize:(NSDictionary *)adSizeDict {
    _styleDict = styleDict;
    _adPosition = -1; // Custom
    _customX = x;
    _customY = y;
    
    if (adSizeDict && adSizeDict.count > 0) {
        _customAdSize = GADAdSizeFromCGSize(CGSizeMake([adSizeDict[@"width"] floatValue], [adSizeDict[@"height"] floatValue]));
        _useCustomAdSize = YES;
    } else {
        _useCustomAdSize = NO;
    }
    
    [self internalRenderTemplate];
}

- (void)internalRenderTemplate {
    if (!_nativeAd) return;
    
    if (_templateView) {
        [_templateView removeFromSuperview];
        _templateView = nil;
    }
    
    NSString *templateId = _styleDict[@"template_id"] ?: @"medium";
    NSString *xibName = [templateId isEqualToString:@"small"] ? @"GADTSmallTemplateView" : @"GADTMediumTemplateView";
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *nibObjects = [bundle loadNibNamed:xibName owner:nil options:nil];
    
    for (id object in nibObjects) {
        if ([object isKindOfClass:[GADTTemplateView class]]) {
            _templateView = (GADTTemplateView *)object;
            break;
        }
    }
    
    if (!_templateView) {
        NSLog(@"PoingAdMob: Could not load template view from XIB: %@", xibName);
        return;
    }
    
    [self applyStylesToTemplate];
    _templateView.nativeAd = _nativeAd;
    
    UIWindow *window = [WindowHelper getCurrentWindow];
    if (window) {
        _templateView.translatesAutoresizingMaskIntoConstraints = NO;
        [window addSubview:_templateView];
        [window bringSubviewToFront:_templateView];
        [self updatePositionLogic];
    }
}

- (void)applyStylesToTemplate {
    NSMutableDictionary *styles = [[NSMutableDictionary alloc] init];
    
    UIColor *mainBG = [GADTTemplateView colorFromHexString:_styleDict[@"main_background_color"]];
    if (mainBG) styles[GADTNativeTemplateStyleKeyMainBackgroundColor] = mainBG;
    
    [self addTextStyleToStyles:styles fromDict:_styleDict[@"primary_text"] 
                   bgKey:GADTNativeTemplateStyleKeyPrimaryBackgroundColor 
                 fontKey:GADTNativeTemplateStyleKeyPrimaryFont 
                colorKey:GADTNativeTemplateStyleKeyPrimaryFontColor];
                
    [self addTextStyleToStyles:styles fromDict:_styleDict[@"secondary_text"] 
                   bgKey:GADTNativeTemplateStyleKeySecondaryBackgroundColor 
                 fontKey:GADTNativeTemplateStyleKeySecondaryFont 
                colorKey:GADTNativeTemplateStyleKeySecondaryFontColor];
                
    [self addTextStyleToStyles:styles fromDict:_styleDict[@"tertiary_text"] 
                   bgKey:GADTNativeTemplateStyleKeyTertiaryBackgroundColor 
                 fontKey:GADTNativeTemplateStyleKeyTertiaryFont 
                colorKey:GADTNativeTemplateStyleKeyTertiaryFontColor];
                
    [self addTextStyleToStyles:styles fromDict:_styleDict[@"call_to_action_text"] 
                   bgKey:GADTNativeTemplateStyleKeyCallToActionBackgroundColor 
                 fontKey:GADTNativeTemplateStyleKeyCallToActionFont 
                colorKey:GADTNativeTemplateStyleKeyCallToActionFontColor];
                
    _templateView.styles = styles;
}

- (void)addTextStyleToStyles:(NSMutableDictionary *)styles fromDict:(NSDictionary *)textDict bgKey:(NSString *)bgKey fontKey:(NSString *)fontKey colorKey:(NSString *)colorKey {
    if (![textDict isKindOfClass:[NSDictionary class]]) return;
    
    UIColor *bg = [GADTTemplateView colorFromHexString:textDict[@"background_color"]];
    if (bg) styles[bgKey] = bg;
    
    UIColor *textC = [GADTTemplateView colorFromHexString:textDict[@"text_color"]];
    if (textC) styles[colorKey] = textC;
    
    float size = [textDict[@"font_size"] floatValue];
    int styleInt = [textDict[@"style"] intValue];
    
    if (size > 0) {
        UIFont *font;
        switch (styleInt) {
            case 1: font = [UIFont boldSystemFontOfSize:size]; break;
            case 2: font = [UIFont italicSystemFontOfSize:size]; break;
            case 3: font = [UIFont fontWithName:@"Courier" size:size]; break;
            default: font = [UIFont systemFontOfSize:size]; break;
        }
        styles[fontKey] = font;
    }
}

- (void)updatePositionLogic {
    if (!_templateView) return;
    
    UIWindow *window = [WindowHelper getCurrentWindow];
    if (!window) return;
    
    [NSLayoutConstraint deactivateConstraints:_activeConstraints];
    [_activeConstraints removeAllObjects];
    
    UILayoutGuide *safeArea = window.safeAreaLayoutGuide;
    
    if (_adPosition == -1) { // Custom
        [_activeConstraints addObject:[_templateView.leftAnchor constraintEqualToAnchor:window.leftAnchor constant:_customX]];
        [_activeConstraints addObject:[_templateView.topAnchor constraintEqualToAnchor:window.topAnchor constant:_customY]];
    } else {
        switch (_adPosition) {
            case 0: // TOP
                [_activeConstraints addObject:[_templateView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor]];
                [_activeConstraints addObject:[_templateView.topAnchor constraintEqualToAnchor:safeArea.topAnchor]];
                break;
            case 1: // BOTTOM
                [_activeConstraints addObject:[_templateView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor]];
                [_activeConstraints addObject:[_templateView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]];
                break;
            case 2: // LEFT
                [_activeConstraints addObject:[_templateView.leftAnchor constraintEqualToAnchor:safeArea.leftAnchor]];
                [_activeConstraints addObject:[_templateView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]];
                break;
            case 3: // RIGHT
                [_activeConstraints addObject:[_templateView.rightAnchor constraintEqualToAnchor:safeArea.rightAnchor]];
                [_activeConstraints addObject:[_templateView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]];
                break;
            case 4: // TOP_LEFT
                [_activeConstraints addObject:[_templateView.leftAnchor constraintEqualToAnchor:safeArea.leftAnchor]];
                [_activeConstraints addObject:[_templateView.topAnchor constraintEqualToAnchor:safeArea.topAnchor]];
                break;
            case 5: // TOP_RIGHT
                [_activeConstraints addObject:[_templateView.rightAnchor constraintEqualToAnchor:safeArea.rightAnchor]];
                [_activeConstraints addObject:[_templateView.topAnchor constraintEqualToAnchor:safeArea.topAnchor]];
                break;
            case 6: // BOTTOM_LEFT
                [_activeConstraints addObject:[_templateView.leftAnchor constraintEqualToAnchor:safeArea.leftAnchor]];
                [_activeConstraints addObject:[_templateView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]];
                break;
            case 7: // BOTTOM_RIGHT
                [_activeConstraints addObject:[_templateView.rightAnchor constraintEqualToAnchor:safeArea.rightAnchor]];
                [_activeConstraints addObject:[_templateView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]];
                break;
            case 8: // CENTER
                [_activeConstraints addObject:[_templateView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor]];
                [_activeConstraints addObject:[_templateView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor]];
                break;
        }
    }
    
    if (_useCustomAdSize) {
        [_activeConstraints addObject:[_templateView.widthAnchor constraintEqualToConstant:_customAdSize.size.width]];
        [_activeConstraints addObject:[_templateView.heightAnchor constraintEqualToConstant:_customAdSize.size.height]];
    } else {
        [_activeConstraints addObject:[_templateView.widthAnchor constraintEqualToAnchor:window.widthAnchor]];
    }
    
    [NSLayoutConstraint activateConstraints:_activeConstraints];
    [window layoutIfNeeded];
}

- (void)updatePosition:(int)position {
    _adPosition = position;
    [self updatePositionLogic];
}

- (void)updateCustomPosition:(int)x y:(int)y {
    _adPosition = -1;
    _customX = x;
    _customY = y;
    [self updatePositionLogic];
}

- (void)destroy {
    [_templateView removeFromSuperview];
    _templateView = nil;
    _nativeAd = nil;
}

- (void)hide {
    _isHidden = YES;
    _templateView.hidden = YES;
}

- (void)show {
    _isHidden = NO;
    _templateView.hidden = NO;
    [self updatePositionLogic];
}

- (float)getWidthInPixels {
    return _templateView.frame.size.width * [UIScreen mainScreen].scale;
}

- (float)getHeightInPixels {
    return _templateView.frame.size.height * [UIScreen mainScreen].scale;
}

#pragma mark - GADAdLoaderDelegate
- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_failed_to_load", [self.UID intValue], [ObjectToGodotDictionary convertNSErrorToDictionaryAsLoadAdError:error]);
}

#pragma mark - GADNativeAdLoaderDelegate
- (void)adLoader:(GADAdLoader *)adLoader didReceiveNativeAd:(GADNativeAd *)nativeAd {
    _nativeAd = nativeAd;
    _nativeAd.delegate = self;
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_loaded", [self.UID intValue]);
}

#pragma mark - GADNativeAdDelegate
- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_impression", [self.UID intValue]);
}

- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_clicked", [self.UID intValue]);
}

- (void)nativeAdWillPresentScreen:(GADNativeAd *)nativeAd {
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_opened", [self.UID intValue]);
}

- (void)nativeAdDidDismissScreen:(GADNativeAd *)nativeAd {
    PoingGodotAdMobNativeOverlayAd::get_singleton()->emit_signal("on_native_overlay_ad_closed", [self.UID intValue]);
}

@end
