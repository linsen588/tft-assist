// TFTAssist.xm — 金铲铲之战 iOS 辅助 v0.4
// 能力：悬浮面板 / ReplayKit 抓屏 / Vision OCR / 阵容建议 / 越狱机自动点击
// 边界：只读画面，不修改任何游戏数据；概率由服务端决定，不可改。

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <stdarg.h>

#if TFT_JAILBREAK
#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <IOKit/hid/IOHIDEvent.h>
#endif

static void TFTWriteLog(NSString *fmt, ...);

static NSString *const kCfgPath  = @"/var/mobile/Library/TFTAssist/lineups.json";
static NSString *const kCalibKey = @"TFT.calib";      // 点击坐标（商店五张卡的中心）
static NSString *const kPrefsKey = @"TFT.prefs";

static const char *tft_hero_catalog = "科加斯|1;璐璐|3;霞|4;拉莫斯|4;卑尔维斯|2;贾克斯|2;纳尔召唤物c|1;厄运小姐|3;奥恩|3;小木灵|2;派克|2;超级机甲|4;内瑟斯|1;伊泽瑞尔|1;布里茨|5;阿萝拉|3;莫德凯撒|2;厄加特|3;烬|5;古拉加斯|2;格雷福斯|5;卡莎|3;菲兹|3;易|4;库奇|4;丽桑卓|1;锐雯|4;贝蕾亚|1;潘森|2;维克托|3;莫甘娜|5;娑娜|5;暗星黑洞|1;阿卡丽|2;金克丝|2;菲奥娜|5;薇古丝|5;努努和威朗普|4;千珏|4;波比|1;劫|5;佐伊|2;雷克塞|1;俄洛伊|3;狂潮虫伤害|1;维迦|1;茂凯|3;崔斯特|1;娜美|4;亚托克斯|1;格温|2;奥瑞利安·索尔|4;凯特琳|1;莎弥拉|3;泰隆|1;乐芙兰分身|4;纳尔|2;卡尔玛|4;纳尔召唤物a|1;乐芙兰|4;蕾欧娜|1;巴德|5;纳尔召唤物d|1;米利欧|2;慎|5;黛安娜|3;拉亚斯特|3;提莫|1;塔姆|4;纳尔召唤物b|1";
static const char *tft_lineups_json = "{\"lineups\":[{\"name\":\"【重装薇古丝九五】4重装战士3牧羊人2暗星\",\"grade\":\"S\",\"units\":[\"莫德凯撒\",\"小木灵\",\"俄洛伊\",\"努努和威朗普\",\"布里茨\",\"娑娜\",\"卡尔玛\",\"巴德\",\"薇古丝\"],\"priority\":[\"无用大棒\",\"反曲之弓\",\"拳套\",\"巨人腰带\"],\"notes\":\"前期开海魔人和未来战士过度，中期搭任意强势卡凑羁绊继续过度\"},{\"name\":\"【牧羊人维克托】3牧羊人2魔术师2暗星2灵能特工\",\"grade\":\"S\",\"units\":[\"派克\",\"俄洛伊\",\"拉亚斯特\",\"莫德凯撒\",\"小木灵\",\"维克托\",\"娜美\",\"丽桑卓\"],\"priority\":[\"无用大棒\",\"巨人腰带\",\"女神之泪\",\"拳套\"],\"notes\":\"定阵前提条件:1.无硬性要求，装备合适，不要太烂即可 2杠1—2杠5：有2未来战士的话装备可以先上，无论连胜连败都能接受，没有就尽量连败吃利息，经济不烂即可。\"},{\"name\":\"【律动转锐雯】5太空律动2魔术师2斗士\",\"grade\":\"S\",\"units\":[\"潘森\",\"塔姆\",\"努努和威朗普\",\"布里茨\",\"奥恩\",\"锐雯\",\"慎\",\"格温\",\"娜美\"],\"priority\":[\"无用大棒\",\"女神之泪\",\"暴风之剑\",\"锁子甲\"],\"notes\":\"推荐前期能合出律动转的情况下去玩。用提莫和格温带装备搭配5律动过渡，多余人口可以开2未来吃经济。\"},{\"name\":\"【幻灵皎月黛安娜】3幻灵战队3牧羊人3法官\",\"grade\":\"S\",\"units\":[\"蕾欧娜\",\"小木灵\",\"俄洛伊\",\"黛安娜\",\"莫甘娜\",\"金克丝\",\"乐芙兰\",\"阿萝拉\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"暴风之剑\",\"女神之泪\"],\"notes\":\"前期不抽卡，为了保证连胜开可以拉人口，（2杠1拉4，2杠5拉5）；有2未来战士或者3幻灵连败开最好。\"},{\"name\":\"【新星薇古丝九五】3新星特攻队2堡垒卫士2斗士\",\"grade\":\"S\",\"units\":[\"茂凯\",\"亚托克斯\",\"慎\",\"塔姆\",\"阿卡丽\",\"菲奥娜\",\"莫甘娜\",\"格雷福斯\",\"薇古丝\"],\"priority\":[\"暴风之剑\",\"巨人腰带\",\"锁子甲\",\"负极斗篷\"],\"notes\":\"血量足够的情况下前中期最好是未来战士拼多多阵容挂凯隐连胜开局，补充经验能够更快上9.为了保证连胜情况下前期可以快速拉人口（2杠1拉4，2杠5拉5，3杠1拉6，3\"},{\"name\":\"【木灵九五烬】3木灵族2暗星2狙神\",\"grade\":\"S\",\"units\":[\"拉莫斯\",\"慎\",\"布里茨\",\"莫甘娜\",\"莫德凯撒\",\"烬\",\"巴德\",\"薇古丝\",\"纳尔\"],\"priority\":[\"暴风之剑\",\"拳套\",\"反曲之弓\",\"无用大棒\"],\"notes\":\"运营节奏：2-1 直接拉 4 人口，按棋子定位直接给装备，冲连胜就别省装备2-3 或 2-5 拉 5 人口，围绕三费主 C 体系补充前排或后排3-1 拉 6 人\"},{\"name\":\"【观星九五烬】3观星者2暗星2狙神\",\"grade\":\"S\",\"units\":[\"努努和威朗普\",\"贾克斯\",\"慎\",\"布里茨\",\"莫甘娜\",\"超级机甲\",\"烬\",\"霞\",\"卡尔玛\"],\"priority\":[\"暴风之剑\",\"拳套\",\"反曲之弓\",\"无用大棒\"],\"notes\":\"定阵前提条件:前中期能走出6连胜以上，5阶段能够上9还有30经济以上，同时血量不能太低，至少要有30血以上.否则可以转下位代替84拼多多霞苟分2杠1 拉4，根据\"},{\"name\":\"【六机甲龙王索尔】6霸天机甲2斗士2暗星\",\"grade\":\"S\",\"units\":[\"超级机甲\",\"厄加特\",\"塔姆\",\"莫德凯撒\",\"奥瑞利安·索尔\",\"莫甘娜\",\"卡尔玛\"],\"priority\":[\"女神之泪\",\"无用大棒\",\"拳套\",\"暴风之剑\"],\"notes\":\"前期根据来牌判断连胜或者连败；核心是不要主动d牌，保证经济良好。\"},{\"name\":\"【薇古丝九五】3旅人3木灵族2暗星\",\"grade\":\"S\",\"units\":[\"拉莫斯\",\"超级机甲\",\"布里茨\",\"莫德凯撒\",\"小木灵\",\"慎\",\"薇古丝\",\"巴德\",\"卡尔玛\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"女神之泪\",\"暴风之剑\"],\"notes\":\"前期用未来战士搭配海魔人过渡，薇古丝装备前期可给伊泽瑞尔带，能连胜开最好，不能连胜开建议中期考虑转其他阵容\"},{\"name\":\"【拼多多魔术师女枪】2新星特工队2游侠2斗士\",\"grade\":\"A\",\"units\":[\"拉亚斯特\",\"茂凯\",\"锐雯\",\"潘森\",\"亚托克斯\",\"格温\",\"慎\",\"厄运小姐\"],\"priority\":[\"女神之泪\",\"暴风之剑\",\"拳套\",\"无用大棒\"],\"notes\":\"定阵前提条件:1.无硬性要求，装备合适，不要太烂即可 2杠1—2杠5：有2未来战士的话装备可以先上，无论连胜连败都能接受，没有就尽量连败吃利息，经济不烂即可。\"},{\"name\":\"【八四飞机库奇】5木灵族2堡垒卫士2织命人\",\"grade\":\"A\",\"units\":[\"小木灵\",\"波比\",\"超级机甲\",\"菲兹\",\"拉莫斯\",\"锐雯\",\"米利欧\",\"库奇\"],\"priority\":[\"暴风之剑\",\"反曲之弓\",\"拳套\",\"锁子甲\"],\"notes\":\"2-1 直接拉 4 人口，按阵容核心位直接分配装备，想打连胜就别舍不得给装备2-3 或 2-5 拉 5 人口，围绕 3 费主 C 体系补前排或后排棋子3-1 拉\"},{\"name\":\"【八四太空律动】5太空律动2魔术师2未来战士\",\"grade\":\"A\",\"units\":[\"奥恩\",\"布里茨\",\"努努和威朗普\",\"锐雯\",\"慎\",\"塔姆\",\"格温\",\"潘森\",\"娜美\"],\"priority\":[\"暴风之剑\",\"女神之泪\",\"无用大棒\",\"巨人腰带\"],\"notes\":\"2-1 拉4 ，装备优先给阵容核心英雄；想稳连胜就别吝啬装备，尽早分配。2-3 或 2-5 拉5 ，根据主c定位合装备。3-1 阶段拉到 6 人口，只要能保住连\"},{\"name\":\"【新星千珏】5新星特攻队2堡垒卫士2斗士\",\"grade\":\"A\",\"units\":[\"茂凯\",\"慎\",\"塔姆\",\"阿卡丽\",\"卑尔维斯\",\"亚托克斯\",\"格雷福斯\",\"凯特琳\",\"千珏\"],\"priority\":[\"暴风之剑\",\"巨人腰带\",\"锁子甲\",\"负极斗篷\"],\"notes\":\"前期根据来牌判断连胜或者连败；核心是不要主动d牌，保证经济良好。经济够好4杠1上8，经济不够就4杠2上8，\"},{\"name\":\"【观星露露】3观星者2魔术师2堡垒卫士\",\"grade\":\"A\",\"units\":[\"亚托克斯\",\"贾克斯\",\"塔姆\",\"茂凯\",\"努努和威朗普\",\"布里茨\",\"莫甘娜\",\"厄运小姐\",\"璐璐\"],\"priority\":[\"无用大棒\",\"拳套\",\"巨人腰带\",\"反曲之弓\"],\"notes\":\"2杠1—2杠5：可以搭配2未来战士或者3海魔人开，不论连胜或者连败都有比较高的经济收益\"},{\"name\":\"【开门派克】3未来战士2灵能特工2斗士\",\"grade\":\"A\",\"units\":[\"潘森\",\"古拉加斯\",\"小木灵\",\"锐雯\",\"拉亚斯特\",\"格温\",\"派克\",\"米利欧\"],\"priority\":[\"暴风之剑\",\"负极斗篷\",\"锁子甲\",\"拳套\"],\"notes\":\"前期不拉人口，不d牌，记住核心六张2费卡即可，连胜或者连败都能接受，尽可能多追三星，（派克和任意前排三星之后，上人口更加重要）\"},{\"name\":\"【新星特工剑圣易】5新星特攻队4狂战士2堡垒卫士\",\"grade\":\"A\",\"units\":[\"亚托克斯\",\"阿卡丽\",\"茂凯\",\"塔姆\",\"菲奥娜\",\"易\",\"卑尔维斯\",\"慎\",\"千珏\"],\"priority\":[\"金铲铲\",\"暴风之剑\",\"反曲之弓\",\"无用大棒\"],\"notes\":\"前期根据来牌判断连胜或者连败；核心是不要8级前主动d牌，保证经济良好。三海魔人或者2未来战士开是比较好的开局。\"},{\"name\":\"【新星海魔卑尔维斯】5新星特工队3海魔人\",\"grade\":\"A\",\"units\":[\"阿卡丽\",\"雷克塞\",\"贝蕾亚\",\"亚托克斯\",\"茂凯\",\"卑尔维斯\",\"莫甘娜\",\"凯特琳\",\"千珏\"],\"priority\":[\"反曲之弓\",\"暴风之剑\",\"负极斗篷\",\"拳套\"],\"notes\":\"前期有装备有2星前排可以拉人口打连胜，有三海魔人开局说天胡，配合斗士、狂战士可以轻松连胜。\"},{\"name\":\"【6斗科加斯】6斗士2暗星2未来战士\",\"grade\":\"A\",\"units\":[\"厄加特\",\"塔姆\",\"古拉加斯\",\"科加斯\",\"潘森\",\"茂凯\",\"阿卡丽\",\"伊泽瑞尔\",\"烬\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"暴风之剑\",\"拳套\"],\"notes\":\"前期依靠2未来战士连胜连败即可（连败给刷新次数，并且星神有概率给体系2星1费，相对收益更高），连胜获得的经验道具不要直接用了，3杠2再用。\"},{\"name\":\"【木灵小法维迦】5木灵族3牧羊人2魔术师\",\"grade\":\"A\",\"units\":[\"拉亚斯特\",\"拉莫斯\",\"波比\",\"小木灵\",\"卡尔玛\",\"提莫\",\"丽桑卓\",\"巴德\",\"维迦\"],\"priority\":[\"无用大棒\",\"拳套\",\"女神之泪\",\"暴风之剑\"],\"notes\":\"定阵前提条件，至少满足以下其一1.开局有2星维迦2.本局星神有维鲁斯3.有宝宝学院海克斯2杠1—2杠5：一般五连败开，排名靠后的星神选秀有机会选2星体系1费卡，\"},{\"name\":\"【拼多多神谕女枪】2新星特工队2灵能特工2斗士\",\"grade\":\"A\",\"units\":[\"茂凯\",\"奥恩\",\"拉亚斯特\",\"亚托克斯\",\"古拉加斯\",\"厄运小姐\",\"维克托\",\"莫甘娜\"],\"priority\":[\"女神之泪\",\"暴风之剑\",\"拳套\",\"无用大棒\"],\"notes\":\"定阵前提条件:1.无硬性要求，装备合适，不要太烂即可 2杠1—2杠5：有2未来战士的话装备可以先上，无论连胜连败都能接受，没有就尽量连败吃利息，经济不烂即可。\"},{\"name\":\"【重装提莫】6重装战士3太空律动3牧羊人\",\"grade\":\"A\",\"units\":[\"布里茨\",\"蕾欧娜\",\"内瑟斯\",\"努努和威朗普\",\"莫德凯撒\",\"俄洛伊\",\"莫甘娜\",\"提莫\",\"丽桑卓\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"巨人腰带\",\"锁子甲\"],\"notes\":\"2-1 到 2-5 回合：通常开局五连败，排名靠后在星神选秀时，有机会拿到能组成 2 星体系的 1 费卡。前期打野怪和刷新商店时，只保留 5 级体系内的卡牌，刷\"},{\"name\":\"【观星崔斯特】4织命人3观星者2游侠\",\"grade\":\"A\",\"units\":[\"贾克斯\",\"锐雯\",\"亚托克斯\",\"泰隆\",\"莫甘娜\",\"崔斯特\",\"凯特琳\",\"库奇\",\"米利欧\"],\"priority\":[\"暴风之剑\",\"女神之泪\",\"无用大棒\",\"巨人腰带\"],\"notes\":\"开局不升人口不D牌只拿体系牌。可以3海魔人或者2未来开局5连败过渡，能补经济的同时星神选秀还有机会补到体系2星1费卡。\"},{\"name\":\"【织命卡牌女警双c】4堡垒卫士4织命人3木灵族\",\"grade\":\"A\",\"units\":[\"波比\",\"拉莫斯\",\"亚托克斯\",\"贾克斯\",\"泰隆\",\"崔斯特\",\"米利欧\",\"库奇\",\"凯特琳\"],\"priority\":[\"反曲之弓\",\"巨人腰带\",\"暴风之剑\",\"无用大棒\"],\"notes\":\"2杠1—2杠5：一般五连败开，排名靠后的星神选秀有机会选2星体系1费卡，前期野怪与商店留牌只留5级体系卡，有2未来战士记得上，没有的话没必要故意开摆连败，装备与\"},{\"name\":\"【重装妖姬乐芙兰】4重装战士3法官2暗星\",\"grade\":\"A\",\"units\":[\"莫德凯撒\",\"蕾欧娜\",\"俄洛伊\",\"小木灵\",\"努努和威朗普\",\"佐伊\",\"卡尔玛\",\"乐芙兰\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"暴风之剑\",\"女神之泪\"],\"notes\":\"前期不抽卡，为了保证连胜开可以拉人口，（2杠1拉4，2杠5拉5）；有未来战士连败开贪刷新次数也行。\"},{\"name\":\"【拼多多卡莎小鱼人】3木灵族2堡垒卫士2游侠2旅人\",\"grade\":\"A\",\"units\":[\"小木灵\",\"拉亚斯特\",\"拉莫斯\",\"菲兹\",\"奥恩\",\"莫甘娜\",\"卡尔玛\",\"卡莎\"],\"priority\":[\"女神之泪\",\"暴风之剑\",\"拳套\",\"巨人腰带\"],\"notes\":\"优先考虑开2未来战士连败开局，以此获得刷新次数，同时2阶段星神提供的三费可以更顺利过渡前期；如果有三费物理c位搭配二星前排，拉人口连胜过渡也行。\"},{\"name\":\"【新星海魔人大卑】5新星特攻队3海魔人2斗士\",\"grade\":\"A\",\"units\":[\"阿卡丽\",\"茂凯\",\"雷克塞\",\"贝蕾亚\",\"亚托克斯\",\"卑尔维斯\",\"莫甘娜\",\"千珏\",\"凯特琳\"],\"priority\":[\"拳套\",\"负极斗篷\",\"反曲之弓\",\"暴风之剑\"],\"notes\":\"前期用海魔人搭配新星过渡即可\"},{\"name\":\"【观星狙霞烬95】3木灵族3观星者3狙神\",\"grade\":\"S\",\"units\":[\"莫德凯撒\",\"拉莫斯\",\"努努和威朗普\",\"拉亚斯特\",\"贾克斯\",\"霞\",\"纳尔\",\"巴德\",\"烬\"],\"priority\":[\"反曲之弓\",\"无用大棒\",\"负极斗篷\",\"锁子甲\"],\"notes\":\"前期用未来或者观星过渡\"}],\"rules\":{\"rollBelowGold\":50,\"levelUpAt\":[4,8,16,28],\"source\":\"XF.金铲铲记牌器 apk assets (setId 17, version 17.17.1)\"}}";

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
    if (!c.lineups.count && strlen(tft_lineups_json) > 10) {
        NSData *d2 = [[NSString stringWithUTF8String:tft_lineups_json] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *j2 = [NSJSONSerialization JSONObjectWithData:d2 options:0 error:nil];
        if ([j2 isKindOfClass:[NSDictionary class]] && [j2[@"lineups"] isKindOfClass:[NSArray class]]) {
            c.lineups = j2[@"lineups"];
            NSNumber *g2 = j2[@"rules"][@"rollBelowGold"];
            if (g2) c.rollBelowGold = g2.integerValue;
        }
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
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL panelTried;
@property (nonatomic, strong) UIView *box;
@property (nonatomic, strong) UIButton *bubble;
@property (nonatomic, strong) AVSpeechSynthesizer *tts;
@property (nonatomic, strong) UISwitch *swVoice;
@property (nonatomic, assign) CFAbsoluteTime lastSpeak;
@property (nonatomic, assign) NSInteger lastAutoIdx;
@property (nonatomic, assign) CFAbsoluteTime lastBuy;
@property (nonatomic, strong) NSMutableDictionary *seen;
@property (nonatomic, strong) NSString *lastShopSig;
@property (nonatomic, strong) NSArray *heroNames;
@property (nonatomic, strong) NSDictionary *heroCost;
@end

@implementation TFTAssist

+ (instancetype)shared {
    static TFTAssist *s; static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [TFTAssist new]; });
    return s;
}

- (void)start {
    if (self.started) return;
    self.started = YES;
    TFTWriteLog(@"start: begin, bundle=%@", [[NSBundle mainBundle] bundleIdentifier]);
    self.cfg = [TFTConfig load];
    [self loadHeroCatalog];
    NSArray *c = [[NSUserDefaults standardUserDefaults] objectForKey:kCalibKey];
    self.calib = [NSMutableArray array];
    for (NSString *s in c) [self.calib addObject:[NSValue valueWithCGPoint:CGPointFromString(s)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self buildPanel];
    });
}

#pragma mark 面板

- (void)buildPanel {
    if (self.panel) return;
    self.panelTried = YES;

    UIWindowScene *scene = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)sc;
        if (ws.activationState == UISceneActivationStateForegroundActive) { scene = ws; break; }
        if (!scene) scene = ws;
    }

    CGRect frame = CGRectMake(10, 90, 340, 380);
    UIWindow *w = scene ? [[UIWindow alloc] initWithWindowScene:scene]
                        : [[UIWindow alloc] initWithFrame:frame];
    w.frame = frame;                       /* 窗口只占面板大小，不挡游戏操作 */
    w.windowLevel = UIWindowLevelAlert + 1000;
    w.backgroundColor = [UIColor clearColor];
    w.hidden = NO;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor clearColor];
    w.rootViewController = vc;
    UIView *root = vc.view;

    /* ---- 面板本体 ---- */
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 380)];
    box.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.95];
    box.layer.cornerRadius = 14; box.layer.masksToBounds = YES;
    box.userInteractionEnabled = YES;
    [root addSubview:box];
    self.box = box;

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, 250, 22)];
    t.text = @"林森制作 · TFT辅助 v0.4"; t.textColor = UIColor.whiteColor;
    t.font = [UIFont boldSystemFontOfSize:14];
    t.userInteractionEnabled = YES;
    [box addSubview:t];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [t addGestureRecognizer:pan];

    /* 收起（不是关闭）：收成小球，点回来 */
    UIButton *mini = [UIButton buttonWithType:UIButtonTypeSystem];
    mini.frame = CGRectMake(302, 4, 32, 28);
    [mini setTitle:@"—" forState:UIControlStateNormal];
    mini.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [mini addTarget:self action:@selector(collapse) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:mini];

    /* 真正关闭：整块隐藏，靠日志开关重新唤出 */
    UIButton *xBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    xBtn.frame = CGRectMake(330, 4, 8, 8);
    xBtn.hidden = YES;
    [box addSubview:xBtn];

    self.headline = [[UILabel alloc] initWithFrame:CGRectMake(12, 28, 316, 18)];
    self.headline.text = @"已加载 · 未开始"; self.headline.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    self.headline.font = [UIFont systemFontOfSize:11];
    [box addSubview:self.headline];

    UIButton *reload = [self btn:@"重载配置" x:12 y:46 w:92];
    [reload addTarget:self action:@selector(reloadCfg) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:reload];
    UIButton *calib = [self btn:@"校准点击" x:112 y:46 w:92];
    [calib addTarget:self action:@selector(startCalib) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:calib];
    UIButton *next = [self btn:@"换阵容" x:212 y:46 w:116];
    [next addTarget:self action:@selector(nextLineup) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:next];

    UIButton *clr = [self btn:@"清空池" x:12 y:74 w:82];
    [clr addTarget:self action:@selector(clearPool) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:clr];

    UILabel *voiceL = [[UILabel alloc] initWithFrame:CGRectMake(100, 78, 62, 18)];
    voiceL.text = @"语音提示"; voiceL.textColor = [UIColor colorWithWhite:0.78 alpha:1];
    voiceL.font = [UIFont systemFontOfSize:11];
    [box addSubview:voiceL];
    self.swVoice = [[UISwitch alloc] initWithFrame:CGRectMake(156, 72, 51, 31)];
    self.swVoice.transform = CGAffineTransformMakeScale(0.64, 0.64);
    self.swVoice.on = YES;
    [box addSubview:self.swVoice];

    UILabel *autoL = [[UILabel alloc] initWithFrame:CGRectMake(212, 78, 70, 18)];
    autoL.text = @"自动点击"; autoL.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    autoL.font = [UIFont systemFontOfSize:11];
    [box addSubview:autoL];
    self.swAuto = [[UISwitch alloc] initWithFrame:CGRectMake(276, 72, 51, 31)];
    self.swAuto.transform = CGAffineTransformMakeScale(0.64, 0.64);
    [box addSubview:self.swAuto];
#if !TFT_JAILBREAK
    self.swAuto.enabled = NO;
    autoL.text = @"自动点(越狱)";
    autoL.textColor = [UIColor colorWithWhite:0.4 alpha:1];
#endif

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(10, 104, 320, 266)];
    tv.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
    tv.textColor = [UIColor colorWithWhite:0.93 alpha:1];
    tv.font = [UIFont fontWithName:@"Menlo" size:10.5] ?: [UIFont systemFontOfSize:10.5];
    tv.editable = NO; tv.layer.cornerRadius = 8;
    tv.text = @"林森制作 · 仅识别不改数据\n1) 上方开关打开识别（首次授权「屏幕录制」）\n2) 语音提示默认开，会念买牌建议\n3) 阵容会按来牌自动切换\n4) 「—」收起成小球，点小球再展开\n\n概率由服务端决定，本工具只做识别与建议";
    [box addSubview:tv];
    self.logView = tv;

    /* ---- 收起后的悬浮球 ---- */
    UIButton *bubble = [UIButton buttonWithType:UIButtonTypeCustom];
    bubble.frame = CGRectMake(0, 0, 60, 60);
    bubble.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.92];
    bubble.layer.cornerRadius = 30; bubble.layer.masksToBounds = YES;
    bubble.layer.borderWidth = 1.5; bubble.layer.borderColor = [UIColor colorWithRed:0.2 green:0.75 blue:1 alpha:1].CGColor;
    [bubble setTitle:@"林" forState:UIControlStateNormal];
    [bubble setTitleColor:[UIColor colorWithRed:0.2 green:0.75 blue:1 alpha:1] forState:UIControlStateNormal];
    bubble.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    bubble.hidden = YES;
    [bubble addTarget:self action:@selector(expand) forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:bubble];
    self.bubble = bubble;
    UIPanGestureRecognizer *bpan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [bubble addGestureRecognizer:bpan];

    self.panel = w;
    [w makeKeyAndVisible];
    TFTWriteLog(@"panel built v0.4 scene=%@ frame=%@", scene ? @"yes" : @"no", NSStringFromCGRect(w.frame));

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (box.window) return;
        UIWindow *kw = nil;
        for (UIWindow *x in UIApplication.sharedApplication.windows)
            if (x.isKeyWindow) { kw = x; break; }
        if (!kw && UIApplication.sharedApplication.windows.count) kw = UIApplication.sharedApplication.windows.firstObject;
        if (kw) {
            [kw.rootViewController.view addSubview:box];
            TFTWriteLog(@"panel fallback -> key window");
        }
    });
}

#pragma mark 收起 / 展开

- (void)collapse {
    self.box.hidden = YES;
    self.bubble.hidden = NO;
    CGRect f = self.panel.frame;
    self.panel.frame = CGRectMake(f.origin.x, f.origin.y, 60, 60);
    TFTWriteLog(@"panel collapsed");
}

- (void)expand {
    self.bubble.hidden = YES;
    self.box.hidden = NO;
    CGRect f = self.panel.frame;
    self.panel.frame = CGRectMake(f.origin.x, f.origin.y, 340, 380);
    TFTWriteLog(@"panel expanded");
}

#pragma mark 语音

- (void)speak:(NSString *)text {
    if (!self.swVoice.isOn || !text.length) return;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - self.lastSpeak < 4.0) return;
    self.lastSpeak = now;
    if (!self.tts) self.tts = [AVSpeechSynthesizer new];
    AVSpeechUtterance *u = [AVSpeechUtterance speechUtteranceWithString:text];
    u.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    u.rate = 0.5f;
    [self.tts speakUtterance:u];
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
    /* 限制在屏幕内，始终留 80pt 可点，避免拖丢找不回来 */
    CGRect sb = [UIScreen mainScreen].bounds;
    f.origin.x = MAX(-f.size.width + 80, MIN(sb.size.width - 80, f.origin.x));
    f.origin.y = MAX(44, MIN(sb.size.height - 80, f.origin.y));
    self.panel.frame = f;
    [g setTranslation:CGPointZero inView:self.panel];
}

- (void)reloadCfg {
    self.cfg = [TFTConfig load];
    [self loadHeroCatalog];
    [self log:@"已重载 %lu 套阵容", (unsigned long)self.cfg.lineups.count];
}

- (void)nextLineup {
    if (!self.cfg.lineups.count) return;
    self.cfg.activeIndex = (self.cfg.activeIndex + 1) % self.cfg.lineups.count;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.cfg.activeIndex) forKey:@"TFT.activeLineup"];
    NSDictionary *lu = self.cfg.lineups[self.cfg.activeIndex];
    [self log:@"切到阵容: %@", lu[@"name"] ?: @"?"];
}

- (void)clearPool {
    [self.seen removeAllObjects];
    self.lastShopSig = @"";
    [self log:@"牌池计数已清空"];
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
        NSMutableArray *obs = [NSMutableArray array];
        for (VNRecognizedTextObservation *o in r.results) {
            VNRecognizedText *t = [[o topCandidates:1] firstObject];
            if (!t.string.length) continue;
            CGRect b = o.boundingBox;   /* 归一化，原点左下 */
            [obs addObject:@{@"t": t.string,
                             @"x": @(b.origin.x), @"y": @(b.origin.y),
                             @"w": @(b.size.width), @"h": @(b.size.height)}];
        }
        [ws analyze:obs];
    }];
    req.recognitionLevel = VNRequestTextRecognitionLevelFast;
    req.recognitionLanguages = @[@"zh-Hans", @"en-US"];
    req.usesLanguageCorrection = NO;
    VNImageRequestHandler *h = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pb options:@{}];
    [h performRequests:@[req] error:nil];
}

#pragma mark 英雄表 / 牌池

- (void)loadHeroCatalog {
    NSMutableArray *names = [NSMutableArray array];
    NSMutableDictionary *cost = [NSMutableDictionary dictionary];
    NSString *cat = [NSString stringWithUTF8String:tft_hero_catalog];
    for (NSString *pair in [cat componentsSeparatedByString:@";"]) {
        NSArray *kv = [pair componentsSeparatedByString:@"|"];
        if (kv.count < 2) continue;
        NSString *n = kv[0];
        if (!n.length) continue;
        [names addObject:n];
        cost[n] = @([kv[1] integerValue]);
    }
    [names sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        if (a.length != b.length) return a.length > b.length ? NSOrderedAscending : NSOrderedDescending;
        return [a compare:b];
    }];
    self.heroNames = names;
    self.heroCost = cost;
    self.seen = [NSMutableDictionary dictionary];
    self.lastShopSig = @"";
}

- (NSInteger)poolTotalForCost:(NSInteger)c {
    /* TFT 标准池：1费22 2费20 3费18 4费12 5费10 */
    switch (c) { case 1: return 22; case 2: return 20; case 3: return 18; case 4: return 12; case 5: return 10; default: return 18; }
}

- (NSUInteger)occurrencesOf:(NSString *)needle in:(NSString *)hay {
    NSUInteger n = 0, loc = 0;
    while (loc < hay.length) {
        NSRange r = [hay rangeOfString:needle options:0 range:NSMakeRange(loc, hay.length - loc)];
        if (r.location == NSNotFound) break;
        n++;
        loc = r.location + r.length;
        if (n > 9) break;
    }
    return n;
}

#pragma mark 决策

- (void)analyze:(NSArray<NSDictionary *> *)obs {
    NSMutableString *all = [NSMutableString string];
    NSMutableString *shopText = [NSMutableString string];
    NSInteger gold = -1, level = -1;

    for (NSDictionary *o in obs) {
        NSString *t = o[@"t"];
        if (!t.length) continue;
        [all appendString:t]; [all appendString:@" "];
        double y = [o[@"y"] doubleValue], x = [o[@"x"] doubleValue];
        if (y < 0.34) { [shopText appendString:t]; [shopText appendString:@" "]; }   /* 商店在屏幕下方 */
        if (level < 0) {
            NSRange r = [t rangeOfString:@"等级"];
            if (r.location != NSNotFound) {
                for (NSString *n in [[t substringFromIndex:r.location] componentsSeparatedByCharactersInSet:
                                     [[NSCharacterSet decimalDigitCharacterSet] invertedSet]])
                    if (n.length && n.length <= 2) { level = n.integerValue; break; }
            }
        }
        if (gold < 0 && y < 0.12 && x < 0.4 && t.length <= 3) {
            NSInteger v = t.integerValue;
            if (v > 0 && v < 200) gold = v;
        }
    }

    /* --- 商店牌识别（只认底部区域） --- */
    NSMutableArray *cards = [NSMutableArray array];
    for (NSString *name in self.heroNames) {
        NSUInteger c = [self occurrencesOf:name in:shopText];
        for (NSUInteger i = 0; i < c; i++) [cards addObject:name];
    }
    NSString *sig = [[cards sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"|"];
    BOOL newShop = (cards.count > 0) && ![sig isEqualToString:self.lastShopSig ?: @""];
    if (newShop) {
        self.lastShopSig = sig;
        for (NSString *n in cards) {
            NSNumber *cur = self.seen[n] ?: @0;
            self.seen[n] = @(cur.integerValue + 1);
        }
    }

    /* --- 自动阵容匹配：用屏幕上出现的阵容牌数量打分 --- */
    NSInteger bestIdx = MIN(self.cfg.activeIndex, (NSInteger)self.cfg.lineups.count - 1);
    NSInteger bestScore = -1;
    for (NSUInteger i = 0; i < self.cfg.lineups.count; i++) {
        NSArray *us = self.cfg.lineups[i][@"units"] ?: @[];
        NSInteger sc = 0;
        for (NSString *u in us) if ([all rangeOfString:u].location != NSNotFound) sc++;
        if (sc > bestScore) { bestScore = sc; bestIdx = (NSInteger)i; }
    }
    if (self.cfg.lineups.count && bestIdx != self.cfg.activeIndex && bestScore >= 3) {
        self.cfg.activeIndex = bestIdx;
        [[NSUserDefaults standardUserDefaults] setObject:@(bestIdx) forKey:@"TFT.activeLineup"];
        NSString *nm = self.cfg.lineups[bestIdx][@"name"] ?: @"?";
        [self log:@"自动换阵(%ld 张命中) → %@", (long)bestScore, nm];
        [self speak:[NSString stringWithFormat:@"自动换到 %@", nm]];
    }

    NSDictionary *lu = nil;
    if (self.cfg.lineups.count) lu = self.cfg.lineups[bestIdx];
    NSArray *units = lu[@"units"] ?: @[];
    NSMutableArray *buy = [NSMutableArray array];
    NSMutableArray *need = [NSMutableArray array];
    for (NSString *u in units) {
        if ([all rangeOfString:u].location != NSNotFound) { if (![buy containsObject:u]) [buy addObject:u]; }
        else [need addObject:u];
    }

    NSMutableString *head = [NSMutableString string];
    if (gold >= 0) [head appendFormat:@"金 %ld ", (long)gold];
    if (level > 0) [head appendFormat:@"Lv %ld ", (long)level];
    if (lu) [head appendFormat:@"| %@", lu[@"name"] ?: @"?"];

    NSString *advice = @"观望";
    if (buy.count) {
        NSString *roll = (gold < 0 || gold >= self.cfg.rollBelowGold) ? @"可 D" : @"别 D";
        advice = [NSString stringWithFormat:@"买 %@（%@）", [buy componentsJoinedByString:@"/"], roll];
    }
    if (gold >= 50 && (level < 9 || level < 0)) advice = [advice stringByAppendingString:@" · 攒钱上人口"];
    else if (level > 0 && level <= 5 && gold >= 30) advice = [advice stringByAppendingString:@" · 该上人口了"];
    if (need.count && need.count <= 4) advice = [advice stringByAppendingFormat:@" · 缺 %@", [need componentsJoinedByString:@"/"]];

    /* --- 牌池剩余（按本局商店出现次数估算） --- */
    NSMutableArray *poolParts = [NSMutableArray array];
    NSArray *watch = newShop ? cards : [self.seen.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [self.seen[b] compare:self.seen[a]];
    }];
    NSMutableSet *done = [NSMutableSet set];
    for (NSString *n in watch) {
        if ([done containsObject:n]) continue;
        [done addObject:n];
        NSInteger cost = [self.heroCost[n] integerValue];
        NSInteger total = [self poolTotalForCost:cost];
        NSInteger used = [self.seen[n] integerValue];
        NSInteger left = total - used; if (left < 0) left = 0;
        [poolParts addObject:[NSString stringWithFormat:@"%@剩%ld", n, (long)left]];
        if (poolParts.count >= 5) break;
    }

    if (newShop) {
        [self log:@"%@ → %@", head.length ? head : @"未识别", advice];
        if (poolParts.count) [self log:@"池: %@", [poolParts componentsJoinedByString:@"  "]];
        if (buy.count) [self speak:[NSString stringWithFormat:@"买 %@", [buy componentsJoinedByString:@"、"]]];
        else if (gold >= 50) [self speak:@"攒钱上人口"];
    } else if (!self.lastShopSig.length) {
        [self log:@"%@ → %@", head.length ? head : @"未识别", advice];
    }

#if TFT_JAILBREAK
    if (self.swAuto.isOn && buy.count && self.calib.count >= 5) {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (now - self.lastBuy > 1.0) {
            self.lastBuy = now;
            NSInteger slot = MIN((NSInteger)buy.count - 1, 4);
            TFTTap([self.calib[slot] CGPointValue]);
        }
    }
#endif
}

@end

#pragma mark - 注入

static void TFTWriteLog(NSString *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[TFTAssist] %@", s);
    NSString *p = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tft.log"];
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], s];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:p];
    if (!fh) {
        [line writeToFile:p atomically:NO encoding:NSUTF8StringEncoding error:nil];
    } else {
        @try { [fh seekToEndOfFile]; [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]]; [fh closeFile]; } @catch (NSException *e) {}
    }
}

%ctor {
    @autoreleasepool {
        TFTWriteLog(@"dylib loaded in %@", [[NSBundle mainBundle] bundleIdentifier]);
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        [nc addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            TFTWriteLog(@"notification: didFinishLaunching");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[TFTAssist shared] start];
            });
        }];

        [nc addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            TFTAssist *a = [TFTAssist shared];
            TFTWriteLog(@"notification: didBecomeActive panel=%@", a.panel ? @"yes" : @"no");
            [a start];
            if (!a.panel) [a buildPanel];
        }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            TFTAssist *a = [TFTAssist shared];
            if (!a.panel) { TFTWriteLog(@"fallback timer -> start"); [a start]; }
        });
    }
}
