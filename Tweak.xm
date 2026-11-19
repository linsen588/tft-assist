// TFTAssist.xm — 金铲铲之战 iOS 辅助 v0.2
// 能力：悬浮面板 / ReplayKit 抓屏 / Vision OCR / 阵容建议 / 越狱机自动点击
// 边界：只读画面，不修改任何游戏数据；概率由服务端决定，不可改。

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import <Vision/Vision.h>
#import <objc/runtime.h>

#if TFT_JAILBREAK
#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <IOKit/hid/IOHIDEvent.h>
#endif

static NSString *const kCfgPath  = @"/var/mobile/Library/TFTAssist/lineups.json";
static NSString *const kCalibKey = @"TFT.calib";      // 点击坐标（商店五张卡的中心）
static NSString *const kPrefsKey = @"TFT.prefs";

#pragma mark - 配置

@interface TFTConfig : NSObject
@property (nonatomic, strong) NSArray<NSDictionary *> *lineups;
@property (nonatomic, assign) NSInteger rollBelowGold;
@property (nonatomic, assign) NSInteger activeIndex;
+ (instancetype)load;
@end

@implementation TFTConfig
+ (instancetype)load {
    TFTConfig *c = [TFTConfig new];
    c.lineups = @[];
    c.rollBelowGold = 50;
    c.activeIndex = 0;
    NSArray *paths = @[kCfgPath,
                       [NSTemporaryDirectory() stringByAppendingPathComponent:@"lineups.json"]];
    for (NSString *p in paths) {
        NSData *d = [NSData dataWithContentsOfFile:p];
        if (!d) continue;
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if (![j isKindOfClass:[NSDictionary class]]) continue;
        if ([j[@"lineups"] isKindOfClass:[NSArray class]]) c.lineups = j[@"lineups"];
        if ([j[@"rules"] isKindOfClass:[NSDictionary class]]) {
            NSNumber *g = j[@"rules"][@"rollBelowGold"];
            if (g) c.rollBelowGold = g.integerValue;
        }
        break;
    }
    NSNumber *idx = [[NSUserDefaults standardUserDefaults] objectForKey:@"TFT.activeLineup"];
    if (idx && idx.integerValue < (NSInteger)c.lineups.count) c.activeIndex = idx.integerValue;
    return c;
}
@end

#pragma mark - 触摸注入（仅越狱）

#if TFT_JAILBREAK
static void TFTSend(CGPoint pt, BOOL down) {
    static IOHIDEventSystemClientRef client = NULL;
    if (!client) client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (!client) return;
    IOHIDEventRef ev = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, 0,
        kIOHIDDigitizerTransducerTypeHand, 0, 0,
        down ? kIOHIDEventPhaseBegan : kIOHIDEventPhaseEnded,
        0, pt.x, pt.y, 0, 0, 0, 0, 0, 0, 0);
    if (ev) {
        IOHIDEventSetIntegerValue(ev, kIOHIDEventFieldIsBuiltIn, 1);
        IOHIDEventSystemClientDispatchEvent(client, ev);
        CFRelease(ev);
    }
}
static void TFTTap(CGPoint pt) {
    TFTSend(pt, YES);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ TFTSend(pt, NO); });
}
#endif

#pragma mark - 主逻辑

@interface TFTAssist : NSObject <RPScreenRecorderDelegate>
@property (nonatomic, strong) UIWindow *panel;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UILabel *headline;
@property (nonatomic, strong) UISwitch *swCapture;
@property (nonatomic, strong) UISwitch *swAuto;
@property (nonatomic, strong) TFTConfig *cfg;
@property (nonatomic, assign) BOOL capturing;
@property (atomic, assign) CFAbsoluteTime lastTick;
@property (nonatomic, strong) NSMutableArray<NSValue *> *calib;
@property (nonatomic, assign) BOOL calibrating;
@property (nonatomic, assign) CFAbsoluteTime lastBuy;
@end

@implementation TFTAssist

+ (instancetype)shared {
    static TFTAssist *s; static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [TFTAssist new]; });
    return s;
}

- (void)start {
    self.cfg = [TFTConfig load];
    NSArray *c = [[NSUserDefaults standardUserDefaults] objectForKey:kCalibKey];
    self.calib = [NSMutableArray array];
    for (NSString *s in c) [self.calib addObject:[NSValue valueWithCGPoint:CGPointFromString(s)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self buildPanel];
    });
}

#pragma mark 面板

- (void)buildPanel {
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
        if ([s isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)s; break; }
    if (!scene) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self buildPanel]; });
        return;
    }
    UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
    w.windowLevel = UIWindowLevelAlert + 200;
    w.frame = CGRectMake(10, 90, 320, 330);
    w.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.93];
    w.layer.cornerRadius = 14; w.layer.masksToBounds = YES;
    w.hidden = NO;
    self.panel = w;

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, 200, 22)];
    t.text = @"TFT 辅助 v0.2"; t.textColor = UIColor.whiteColor;
    t.font = [UIFont boldSystemFontOfSize:14];
    [w addSubview:t];

    self.swCapture = [[UISwitch alloc] initWithFrame:CGRectMake(262, 4, 51, 31)];
    self.swCapture.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [self.swCapture addTarget:self action:@selector(onCapture:) forControlEvents:UIControlEventValueChanged];
    [w addSubview:self.swCapture];

    self.headline = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, 296, 20)];
    self.headline.text = @"未开始"; self.headline.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    self.headline.font = [UIFont systemFontOfSize:11];
    [w addSubview:self.headline];

    UIButton *reload = [self btn:@"重载配置" x:12 y:54 w:92];
    [reload addTarget:self action:@selector(reloadCfg) forControlEvents:UIControlEventTouchUpInside];
    UIButton *calib = [self btn:@"校准点击" x:112 y:54 w:92];
    [calib addTarget:self action:@selector(startCalib) forControlEvents:UIControlEventTouchUpInside];
    UIButton *next = [self btn:@"换阵容" x:212 y:54 w:96];
    [next addTarget:self action:@selector(nextLineup) forControlEvents:UIControlEventTouchUpInside];

    UILabel *autoL = [[UILabel alloc] initWithFrame:CGRectMake(12, 84, 120, 20)];
    autoL.text = @"自动点击(越狱)"; autoL.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    autoL.font = [UIFont systemFontOfSize:11];
    [w addSubview:autoL];
    self.swAuto = [[UISwitch alloc] initWithFrame:CGRectMake(140, 78, 51, 31)];
    self.swAuto.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [w addSubview:self.swAuto];
#if !TFT_JAILBREAK
    self.swAuto.enabled = NO;
    autoL.text = @"自动点击(需越狱)";
    autoL.textColor = [UIColor colorWithWhite:0.4 alpha:1];
#endif

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(10, 110, 300, 208)];
    tv.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
    tv.textColor = [UIColor colorWithWhite:0.93 alpha:1];
    tv.font = [UIFont fontWithName:@"Menlo" size:10.5] ?: [UIFont systemFontOfSize:10.5];
    tv.editable = NO; tv.layer.cornerRadius = 8;
    tv.text = @"1) 右上开关开始识别（首次授权屏幕录制）\n2) 「校准点击」依次点商店 5 张卡\n3) 越狱机可开「自动点击」\n\n概率由服务端决定，本工具只做识别与建议";
    [w addSubview:tv];
    self.logView = tv;

    // 拖动
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [t addGestureRecognizer:pan];
    t.userInteractionEnabled = YES;
}

- (UIButton *)btn:(NSString *)title x:(CGFloat)x y:(CGFloat)y w:(CGFloat)w {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(x, y, w, 24);
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:11];
    b.backgroundColor = [UIColor colorWithWhite:0.22 alpha:1];
    b.layer.cornerRadius = 6;
    b.tintColor = UIColor.whiteColor;
    [self.panel addSubview:b];
    return b;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint d = [g translationInView:self.panel];
    CGRect f = self.panel.frame;
    f.origin.x += d.x; f.origin.y += d.y;
    self.panel.frame = f;
    [g setTranslation:CGPointZero inView:self.panel];
}

- (void)reloadCfg {
    self.cfg = [TFTConfig load];
    [self log:@"已重载 %lu 套阵容", (unsigned long)self.cfg.lineups.count];
}

- (void)nextLineup {
    if (!self.cfg.lineups.count) return;
    self.cfg.activeIndex = (self.cfg.activeIndex + 1) % self.cfg.lineups.count;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.cfg.activeIndex) forKey:@"TFT.activeLineup"];
    NSDictionary *lu = self.cfg.lineups[self.cfg.activeIndex];
    [self log:@"切到阵容: %@", lu[@"name"] ?: @"?"];
}

- (void)startCalib {
    self.calibrating = YES;
    [self.calib removeAllObjects];
    [self log:@"校准：请依次点商店 5 张卡（点 5 下）"];
}

- (void)onCapture:(UISwitch *)s {
    if (s.isOn) [self startCapture]; else [self stopCapture];
}

- (void)log:(NSString *)fmt, ... {
    va_list ap; va_start(ap, fmt);
    NSString *str = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *lines = [(self.logView.text ?: @"") componentsSeparatedByString:@"\n"];
        if (lines.count > 14) lines = [lines subarrayWithRange:NSMakeRange(lines.count - 14, 14)];
        self.logView.text = [[lines componentsJoinedByString:@"\n"] stringByAppendingFormat:@"\n%@", str];
        [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 0)];
        self.headline.text = str;
    });
}

#pragma mark 抓屏

- (void)startCapture {
    RPScreenRecorder *rec = [RPScreenRecorder sharedRecorder];
    rec.delegate = self;
    __weak typeof(self) ws = self;
    [rec startCaptureWithHandler:^(CMSampleBufferRef buf, RPSampleBufferType type, NSError *err) {
        if (type != RPSampleBufferTypeVideo || !buf) return;
        typeof(self) s = ws; if (!s) return;
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (now - s.lastTick < 0.5) return;
        s.lastTick = now;
        [s ocrBuffer:buf];
    } completionHandler:^(NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err) { [self log:@"抓屏失败: %@", err.localizedDescription]; self.swCapture.on = NO; }
            else [self log:@"识别已启动"];
        });
    }];
    self.capturing = YES;
}

- (void)stopCapture {
    [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError *e) {}];
    self.capturing = NO;
    [self log:@"识别已停止"];
}

- (void)ocrBuffer:(CMSampleBufferRef)buf {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buf);
    if (!pb) return;
    __weak typeof(self) ws = self;
    VNRecognizeTextRequest *req = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *r, NSError *e) {
        NSMutableArray *arr = [NSMutableArray array];
        for (VNRecognizedTextObservation *o in r.results) {
            VNRecognizedText *t = [[o topCandidates:1] firstObject];
            if (t.string.length) [arr addObject:t.string];
        }
        [ws analyze:arr];
    }];
    req.recognitionLevel = VNRequestTextRecognitionLevelFast;
    req.recognitionLanguages = @[@"zh-Hans", @"en-US"];
    req.usesLanguageCorrection = NO;
    VNImageRequestHandler *h = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pb options:@{}];
    [h performRequests:@[req] error:nil];
}

#pragma mark 决策

- (void)analyze:(NSArray<NSString *> *)lines {
    NSString *all = [lines componentsJoinedByString:@" | "];
    NSInteger gold = -1, level = -1;
    for (NSString *s in lines) {
        NSString *t = [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (gold < 0 && t.length <= 3 && [t integerValue] > 0 && [t integerValue] < 200) gold = t.integerValue;
        NSRange r = [s rangeOfString:@"等级"];
        if (r.location != NSNotFound && level < 0) {
            NSString *tail = [s substringFromIndex:r.location];
            for (NSString *n in [tail componentsSeparatedByCharactersInSet:
                                 [[NSCharacterSet decimalDigitCharacterSet] invertedSet]])
                if (n.length && n.length <= 2) { level = n.integerValue; break; }
        }
    }

    NSDictionary *lu = nil;
    if (self.cfg.lineups.count) lu = self.cfg.lineups[MIN(self.cfg.activeIndex, (NSInteger)self.cfg.lineups.count - 1)];
    NSArray *units = lu[@"units"] ?: @[];
    NSMutableArray *buy = [NSMutableArray array];
    for (NSString *u in units) if ([all containsString:u] && ![buy containsObject:u]) [buy addObject:u];

    NSMutableString *head = [NSMutableString string];
    if (gold >= 0) [head appendFormat:@"金 %ld ", (long)gold];
    if (level > 0) [head appendFormat:@"Lv %ld ", (long)level];
    if (lu) [head appendFormat:@"| %@", lu[@"name"] ?: @"?"];

    NSString *advice = @"观望";
    if (buy.count) {
        advice = (gold < 0 || gold >= self.cfg.rollBelowGold)
            ? [NSString stringWithFormat:@"买 %@（可 D）", [buy componentsJoinedByString:@"/"]]
            : [NSString stringWithFormat:@"买 %@（别 D）", [buy componentsJoinedByString:@"/"]];
    } else if (gold > 50) advice = @"攒钱上人口";

    [self log:@"%@ → %@", head.length ? head : @"未识别", advice];

#if TFT_JAILBREAK
    if (self.swAuto.isOn && buy.count && self.calib.count >= 5) {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (now - self.lastBuy > 1.0) {
            self.lastBuy = now;
            // 命中哪张卡就点哪张（简化：按配置顺序取第一个命中）
            NSInteger slot = MIN((NSInteger)buy.count - 1, 4);
            TFTTap([self.calib[slot] CGPointValue]);
        }
    }
#endif
}


@end

#pragma mark - 注入

%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL r = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [[TFTAssist shared] start]; });
    return r;
}
%end
