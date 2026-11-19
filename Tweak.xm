// TFTAssist.xm — 金铲铲之战 iOS 辅助 v0.5.1
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
static const char *tft_hex_catalog = "存心失利|2;花到上头|2;装备百宝袋 I|1;潘朵拉的装备|1;打捞桶|2;清晰头脑|2;并肩作战 I|1;部分飞升|1;应急护甲 I|1;秘法帮派|1;休眠锻炉|1;嘀个痛快！ I|1;后期专家|1;潘朵拉的备战席|1;节外生枝|1;游神的盟友|1;一，二，三|1;别再错过|1;治疗法球 I|1;团队建设|1;一，二，五！|1;黑铁资产|1;不拘一格|1;对冲基金|3;银汤匙|1;基础装备自助餐|1;有用之材 I|1;四费增援|2;潘朵拉的装备 II|2;打捞桶+|2;源计划植入|2;飞升|2;星界赐福 II|2;应急护甲 II|2;嘀嘀街区|2;源计划上行链路|2;变形重组器|1;珠光莲花 I|2;好事成双 II|2;大百宝袋|2;阿福的百宝袋|3;纷乱头脑|2;幸运手套|3;生日礼物|3;游神的眷顾|2;治疗法球 II|2;了解你的敌人|2;成吨的属性！|2;英勇福袋|2;物尽其用|2;潘朵拉的装备 III|3;升级咯！|3;星界赐福 III|3;棱彩门票|3;新人入队|3;秘法帮派 II|3;嘀嘀街区加强版|2;便携锻炉|2;珠光莲花 II|3;光明圣物|3;金蛋|3;耐心学习|2;诅咒冠冕|3;活体锻炉|3;幸运手套+|3;珍藏财宝|3;交给运气|3;成吨的伤害|3;英勇福袋+|2;遥遥领先|3;混沌召唤|3;来个好伙计！|3;新纪元+|2;物尽其用+|2;新人入队+|3;大买特买|3;节外生枝+|1;成吨的伤害+|3;英勇福袋++|2;进攻宣告|1;耐心是一种美德|1;核心位的觉悟|1;弑君突刺|1;精心打造|1;假人化|1;终身黄铜 I|2;腐蚀|1;玻璃大炮 I|1;白银命运|1;人生切片|1;轻量魔法投掷|1;锻造挚友|1;拳击课程|1;战时补给：巨人腰带|1;战时补给：无用大棒|1;战时补给：女神之泪|1;战时补给：暴风大剑|1;战时补给：反曲之弓|1;认知税|1;认知税+|1;博弈开启|1;高塔|1;手气不错|1;拥抱 I|1;拥抱 II|2;小小福袋|1;双子守护神|1;远征|1;电火花 I|1;扩展包|2;残留魔力|1;灌铅骰子|1;纵深 I|1;弈子配送|1;弈子配送+|1;弈子配送++|1;高瞻远瞩|1;资本利得 I|1;连败连胜才能连鸡|1;仙灵报恩|1;烧起来|1;绽灵花的约定|2;投资+|3;挖角|2;反响|2;值得等待|2;爆炸式增长|2;发条增速器|2;双排|2;专属定制|2;魔法投掷|2;征战之路|2;不侦察，不变阵|2;投资策略 I|2;强化之能量|1;金色炊具|2;终身黄铜 II|3;玻璃大炮 II|2;恶意货币化|2;泪流成河|2;黄金命运|2;黄金命运+|2;砍价高手|2;应急护盾|2;白银命运+|1;独自升级|2;时间跳跃|2;更要命的帽子|3;更要命的战刃|3;救赎盔甲|2;承诺之护|2;心之钢|2;高级贷款+|2;炽天使之拥|2;单身板甲|2;三相庇护|2;认知过载|2;利落保镖|2;双城赢家|2;生日聚会|2;宝宝学院|2;8级嘀干的传说|2;三幻神|2;杖之工匠|2;剑之工匠|2;蔓延之根|2;摇钱树|3;绝境反击|3;挑战者的优雅|2;金霖龙|2;获得21金币|2;后期收益|2;纺织魔法|2;水乳交融|3;一波带走俩|2;蔓延之根+|2;镀金钢铁|2;贪财|2;电火花 II|2;黄金赌约|3;黄金赌约+|3;黄金赌约++|3;扩展包+|2;四之力|2;残留魔力+|1;亡眼射手|2;纵深 II|2;资本利得 II|2;等待得值|2;顶尖构筑|2;致命丽花|2;装备提炼|2;世纪和解|2;巨化术|2;兽性本能|2;仙灵报恩+|1;欧米茄之怪|2;自然庇护所|2;女巫使魔|2;毛茸茸小朋友|2;太阳的抉择|2;黑暗仪式|2;野兽出没|2;日月同辉|2;是我，宝贝！|2;投资++|3;值得等待 II|3;爆炸式增长+|2;上进心|3;大而有力|3;金鳞精粹|3;加冕礼|3;腰带溢流|3;法杖溢流|3;大剑溢流|3;1个霸符，2个霸符|3;锅铲厨房|3;意料之中的意外|3;投资策略 II|3;棱彩命运|3;白银命运++|1;坚守防线|3;高级贷款|2;灵魂唤醒|3;正义报复|3;男爵幻域|3;神力天铸|3;纹章树|3;可大可小|3;棱彩命运+|3;贸易中心|3;甜点|3;厨神阿福|2;秘法帮派 II+|3;秘法帮派 II++|3;奢侈品订购|3;纹章树+|3;贪财+|2;后排蓝图|2;前线地基|2;扩展包++|2;残留魔力++|1;基础装备大冒险|3;拼盘天梯|3;纵深 III|3;锻造器套娃|3;弈子套娃|3;日月同辉+|2;创世神|3;灵活摇摆|3;硬性承诺|3;锻造器套娃+|3;兽性本能+|2;明智消费|3;代谢增速器|2;羽量级选手 I|1;三费小组|2;战争财宝 I|1;开摆|1;最佳好友I|1;成群结队|1;打气 I|1;珍藏财宝 I|1;白银门票|1;药剂师 I|1;源计划巨块 I|1;冒险举动|1;酷热打击|1;联合抵抗 I|1;极客发明|2;挂件也疯狂|1;学习拼读|2;赚大发|2;汲取习性 I|1;利滚利|2;羽量级选手 II|2;前进之路|3;二进制空投|3;战争财宝 II|2;最佳好友II|2;快速思考|3;公理圆弧II|2;精英战士之徽|2;让精英飞|3;AI程序之徽|2;AI程序之冕|3;秘术卫士之徽|2;秘术卫士之冕|3;幻灵战队之徽|2;幻灵战队之冕|3;斗士之徽|2;斗士之冕|3;灵能使之徽|2;灵能使之冕|3;平民英雄之徽|2;平民英雄之冕|3;强袭枪手之徽|2;强袭枪手之冕|3;护卫之徽|2;护卫之冕|3;决斗大师之徽|2;决斗大师之冕|3;战斗机甲之徽|2;战斗机甲之冕|3;小天才之徽|2;小天才之冕|3;黑客之冕|3;爱心使者之徽|2;爱心使者之冕|3;源计划：激光特工之徽|2;吉祥物之徽|2;吉祥物之冕|3;福牛守护者之徽|2;福牛守护者之冕|3;淘气包之徽|2;情报特工之徽|2;情报特工之冕|3;混沌战士之冕|3;星之守护者之徽|2;星之守护者之冕|3;地下魔盗团之徽|2;地下魔盗团之冕|3;天生二星|2;打气 II|2;珍藏财宝 II|2;灌注|2;整活锻炉|3;刀下取金|2;理想主义|2;天涯若比邻|2;黄金门票|2;药剂师 II|2;源计划巨块 II|2;投资回报|2;不是今天|2;常客优惠|2;吾弓听命于您|2;吾剑听命于您|2;魔杖|2;主打一个陪伴|2;联合抵抗 II|2;施法即是防御|2;不屈意志|1;殉道者|2;行家里手|2;三费成众|2;二费活力|2;炼狱合约|3;健康信用|3;有用之材 II|2;双喜临门I|2;替罪羊|2;重量级人物|2;低利率|2;激昂墓志铭|2;汲取习性 II|2;冲榜战士|2;天降金币|2;漫游训练师 I|2;利滚利加强版|2;最小巨人|3;万用瞄准镜 II|3;羽量级选手 III|3;终极飞升|3;战争财宝 III|3;小巨人|1;恶魔契约|3;游神的神选|3;入门套件|3;打气 III|3;无尽部落|3;药剂师 III|3;源计划巨块 III|3;临别赠礼|1;漫游训练师 II|3;不破壁垒|3;对冲基金++|3;双喜临门II|3;光明重构器|3;天降金币+|2;便携锻炉+|2;高端购物|3;便携锻炉++|2;升星之运|1;闪若金鳞|2;金色追求|2;前瞻思维|2;大怪兽来袭！|2;叠上叠|4;吞噬灵魂|4;禁魔链|4;激光专注|4;无人机坪|4;正义冲拳|4;鸡牛特战队|4;烈焰弹射|4;酬劳已到|4;启明奇点|4;透光屏障|4;怒之领域|4;巨鳄狂袭|4;誓守此城|4;刀锋领主|4;动态防御|4;机械飞爪|4;精心培养|4;生机迸发|4;活力再生|4;大闹天宫|4;登神长阶|4;正义距离|4;更大更好的圆盾|4;无限圆盾|4;姐妹|4;群星依旧炸！|4;嗜火|4;火热斗志|4;适应性防守|4;通缉令|4;无双挑战|4;剑与蔷薇|4;神龙摆尾|4;净化之金钟罩|4;分享驭铁术|4;送餐小费|4;无尽披萨|4;浪客之风|4;浪客精神|4;猫之精准|4;旺盛精力|4;坚如磐石|4;守护者的斗志|4;德莱文联盟|4;最佳组件|4;不屈之劲|4;平行宇宙|4;咒能高涨|4;得胜归来|4;混响之刃|4;进入夜晚|4;扩散射击|4;巨无霸|4;蛮牛威压|4;肉食者|4;星界屏障|4;能量网|4;暗流|4;霜冻苔原|4;霜燃|4;睡眠时间|4;双重气泡|4;锥刺甲壳|4;重甲龙龟|4;轻纱飞漾|4;天赋异禀|4;赦除|4;特工编队|4;宗师训练|4;无情连打|4;协助瞄准|4;镜花水月|4;侦察小队|4;多重射击|4;气态巨人杀手|4;恐惧即是自在|4;化石为盾|4;岩雀|4;痛贯心灵|4;最佳拍档|4;灭绝事件|4;幸运流星|4;虚空瞄准镜|4;为血而来|4;战斗兔佣兵|4;枪林弹雨|4;评级与交火|4;铤而走险|4;冲拳礼仪|4;再生护盾|4;细胞组织|4;弹性弹弓|4;禁奥义!|4;夺影术|4;升级：狂暴|4;极冰寒狱|4;碎冰|4;时空断裂|4;毁灭性共振|4;暗裔同化|4;赐死剑气|4;当面推球|4;笑会传染|4;装备升级|4;赋能后备队|4;夸张播报|4;五号飓风|4;完美的日炎耀斑|4;蚀天盾|4;没那么重金属|4;破灭之锤|4;更可怕的乌鸦|4;绝对堕落|4;亮闪闪|4;涨潮|4;装弹完毕|4;穿甲弹|4;浪人 I|1;星界赐福 I|1;复苏之风|1;大哥罩我|1;伺机待发I|1;运力不足|1;午餐钱|1;浪人 II|2;四费小组|1;伺机待发II|2;碰撞测试假人|2;小伙伴|2;新纪元|2;赏金战士|2;高压电|2;棘刺镀板铠甲|2;小而关键|3;延迟开始|1;安慰剂|1;重启任务|1;以眼还眼|1;餐桌剩菜|1;巨型泰坦|1;幸存者|1;列队|1;薅羊毛|1;无序进化|1;战时补给：拳套|1;集中火力|1;大炮火力网|1;涌泉公理|1;气旋公理|1;森罗公理|1;岩土公理|1;炽焰公理|1;安慰剂+|1;两把刷子|2;以眼还眼+|1;火爆甩卖|1;王冠意志|2;长矛意志|2;权杖意志|2;三项赛 I|2;由二生嘀|2;魔像化|2;一对4|2;灵魂连接|2;王冠之重|2;低调炫耀|2;大刷特刷|2;关爱包裹|2;寻宝|2;储蓄账户|2;秘传奥义|2;鲜血祭品|2;火上浇油|2;优柔寡断 I|2;信仰之跃|1;暮光试炼|2;无差别攻击|2;普雷西典保卫战|2;达克威尔入侵|2;三，三，三！|2;举重比赛|2;绝命毒师|2;狂野生长|2;行走于真实之道 I|2;班德尔奖金 I|2;以绪塔尔探险家|2;德玛西亚万岁|2;解封魔武|2;破灭使者|2;沙海奥秘|3;海克斯飞门之旅|2;混沌魔法|2;破败之王|2;海牛阿福的锅铲战术|2;进化，然后征服|2;猛将的荣耀|2;星界感召|2;三项赛 II|3;饭厅|2;九条命|3;挑个好伙计！|2;优柔寡断 II|3;登上最高峰|3;点击即送|3;巨龙卫士|3;五角星|3;成长型思维|3;与狼共舞|3;散件丰收日|3;行走于真实之道 II|3;班德尔奖金 II|3;元初公理|3;世界符文|3;希尔科的复仇|2;羁绊树+|3;独一无二|4;升级费用降低|4;刷新开局|4;灵魂熔炉|4;三阶段强化|4;商店刷新|4;二阶段强化|4;嚎哭深渊|4;4级开局|4;全自动|4;四费开局|4;两生花影|4;暮光试炼 II|3;应急护甲|1;D个痛快！ I|1;三费之力 I|1;意气相投 I|1;愤怒 I|1;蛟龙得水 I|1;大利大吉|1;重装保镖|1;成群结队 I|1;一二二三|1;源计划血蛭 I|1;无心开D|1;边玩边拿|2;数学游戏|1;长板效应 I|1;保持节奏|1;八缺一|1;延时补给I|1;紫气东来|1;DD街区|2;法力回涌|2;意气相投 II|2;天命护符|2;愤怒 II|2;先声夺人|2;蛟龙得水 II|2;启蒙教学|2;武圣赐福|2;巧匠赐福|2;不灭的愤怒|2;战亦有道|2;仙途|2;落红护花|2;魔神登场|2;腥红之力|2;天神启示|2;天神时代|2;断魄夺魂|2;神御护盾|2;破防弹射|2;狙神之眼|2;神盾即是神佑|2;三国猛将阵线|2;趁手兵器|2;白魔法|2;龙魂咆哮|2;决斗之舞|2;福禄临门|2;熊熊斗志|2;明昼灵光|2;源计划血蛭 II|2;升星之运II|2;奋起直追|2;我是主角|2;鱼跃龙门|2;沙漏战甲|2;狂战之神 II|2;长板效应 II|2;超级英雄|2;邪神契约|2;最终壁垒|2;不息剑意|2;神盾之威|2;有用大棒|2;斗士之志|2;扎根|2;疾如风掠如火|2;巨龙加护|2;动感二人组|2;最佳好友III|3;腥红之月之冕|3;天神之冕|3;永恒之森之冕|3;龙魂之冕|3;福星之冕|3;灵魂莲华明昼之冕|3;三国之冕|3;刺客之冕|3;神盾使之冕|3;魔法师之冕|3;秘术师之冕|3;战神之冕|3;重装战士之冕|3;摄魂使之冕|3;意气相投 III|3;天选成双|3;天选中的天选|2;人定胜天|3;蛟龙得水 III|3;陨落赠礼|2;源计划血蛭 III|3;炫目之速|3;长板效应 III|3;小而致命|3;少D为妙|2;装备天梯|1;乞亦有择|1;战斗绷带 I|1;最终抵抗|1;同排活力 I|1;过量治疗|2;孤胆英雄|1;拾荒者|2;法力流 I|1;攀登天梯 I|1;后援|1;健康就是财富 I|1;逆风斗志|1;带装进组|1;单车变摩托|1;越D越有 I|1;合一得二|1;福星保险|1;双倍头铁|2;假装摸鱼|2;为死者复仇|2;战斗绷带 II|2;同排活力 II|2;咒刃|2;做大做强|2;吸血生机|2;多元化投资+|1;崇高冒险|3;商店故障|2;操纵商店+|1;月光|2;由二生D|2;厄运保护|2;假人金币|2;法力流 II|2;满意的织法者|2;攀登天梯 II|2;炽热灵魂 I|2;硬化护盾|2;透体莲花 I|2;健康就是财富 II|2;预组小队|2;预组小队+|2;储蓄达人|2;越D越有 II|2;羁绊大师|2;热辣火锅|2;饺子蒸笼|2;迎新利是|2;据城而守|2;两元店|2;全能天选|2;闪若金鳞+|2;双重目的|3;刺客的工具箱|3;射手的工具箱|3;最大规模|3;高级月光|3;神器工厂|3;精心赋能|3;炽热灵魂 II|3;透体莲花 II|3;有力援军|3;越D越有 III|3;半神献祭 III|3;同源之力|3;新春集市|3;超级商店|3;四资五费|3";
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
@property (nonatomic, strong) UIView *panel;
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
@property (nonatomic, strong) UILabel *statusLine;
@property (nonatomic, strong) UIButton *btnCapture;
@property (nonatomic, strong) NSDictionary *hexLevel;
@property (nonatomic, strong) NSArray *hexNames;
@property (nonatomic, assign) BOOL dumpNext;
@property (nonatomic, assign) BOOL forceFrame;
@property (nonatomic, strong) NSString *lastHexAdvice;
@property (nonatomic, assign) NSInteger lastLineCount;
@property (nonatomic, assign) NSInteger panelTriedCount;
@property (nonatomic, assign) CFAbsoluteTime lastBuy;
@property (nonatomic, strong) NSMutableDictionary *seen;
@property (nonatomic, strong) NSString *lastShopSig;
@property (nonatomic, strong) NSArray *heroNames;
@property (nonatomic, strong) NSDictionary *heroCost;
@end

@interface TFTVC : UIViewController
@property (nonatomic, assign) UIInterfaceOrientationMask mask;
@end

@implementation TFTVC
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return self.mask; }
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
@end

@implementation TFTAssist

+ (instancetype)shared {
    static TFTAssist *s; static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [TFTAssist new]; });
    return s;
}

- (void)collapse {
    self.box.hidden = YES;
    self.bubble.hidden = NO;
    CGRect f = self.panel.frame;
    self.panel.frame = CGRectMake(f.origin.x, f.origin.y, 60, 60);
    [self.panel.superview bringSubviewToFront:self.panel];
    TFTWriteLog(@"panel collapsed");
}

- (void)expand {
    self.bubble.hidden = YES;
    self.box.hidden = NO;
    CGRect f = self.panel.frame;
    self.panel.frame = CGRectMake(f.origin.x, f.origin.y, 340, 404);
    [self.panel.superview bringSubviewToFront:self.panel];
    TFTWriteLog(@"panel expanded");
}

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

- (void)start {
    if (self.started) return;
    self.started = YES;
    TFTWriteLog(@"start: begin, bundle=%@", [[NSBundle mainBundle] bundleIdentifier]);
    self.cfg = [TFTConfig load];
    [self loadHeroCatalog];
    [self loadHexCatalog];
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

    /* 直接挂到游戏自己的 rootVC.view 上：
       - 跟着游戏一起转屏，不会再"反了"
       - 最小化时球和面板在同一个容器里，不会消失 */
    UIWindow *host = nil;
    for (UIWindow *x in UIApplication.sharedApplication.windows) {
        if (x.isKeyWindow) { host = x; break; }
    }
    if (!host && UIApplication.sharedApplication.windows.count)
        host = UIApplication.sharedApplication.windows.firstObject;
    UIViewController *hostVC = host.rootViewController;
    UIView *root = hostVC.view;
    if (!root) {
        if (!self.panelTriedCount) self.panelTriedCount = 0;
        if (++self.panelTriedCount < 20) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ [self buildPanel]; });
        } else {
            TFTWriteLog(@"buildPanel: no root view after retries");
        }
        return;
    }
    self.panelTried = YES;

    CGRect rf = root.bounds;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, 60, 340, 404)];
    container.backgroundColor = [UIColor clearColor];
    [root addSubview:container];
    self.panel = container;
    TFTWriteLog(@"panel v0.5.2 attached to %@ (%.0fx%.0f)", NSStringFromClass([root class]), rf.size.width, rf.size.height);

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 404)];
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = box.bounds;
    grad.colors = @[(id)[UIColor colorWithWhite:0.13 alpha:0.97].CGColor,
                    (id)[UIColor colorWithWhite:0.06 alpha:0.97].CGColor];
    [box.layer insertSublayer:grad atIndex:0];
    box.layer.cornerRadius = 16; box.layer.masksToBounds = YES;
    box.layer.borderWidth = 1; box.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    [container addSubview:box];
    self.box = box;

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, 240, 22)];
    t.text = @"林森制作 · TFT辅助 v0.5.2"; t.textColor = UIColor.whiteColor;
    t.font = [UIFont boldSystemFontOfSize:14];
    t.userInteractionEnabled = YES;
    [box addSubview:t];
    [t addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)]];

    UIButton *mini = [UIButton buttonWithType:UIButtonTypeSystem];
    mini.frame = CGRectMake(300, 6, 34, 26);
    [mini setTitle:@"—" forState:UIControlStateNormal];
    mini.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [mini addTarget:self action:@selector(collapse) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:mini];

    self.statusLine = [[UILabel alloc] initWithFrame:CGRectMake(14, 30, 312, 16)];
    self.statusLine.text = @"● 未开始 · 点「开始识别」并授权屏幕录制";
    self.statusLine.textColor = [UIColor colorWithWhite:0.62 alpha:1];
    self.statusLine.font = [UIFont fontWithName:@"Menlo" size:10] ?: [UIFont systemFontOfSize:10];
    [box addSubview:self.statusLine];

    self.btnCapture = [self btn:@"开始识别" x:14 y:50 w:96];
    [self.btnCapture addTarget:self action:@selector(toggleCapture) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:self.btnCapture];
    UIButton *testBtn = [self btn:@"测试识别" x:118 y:50 w:96];
    [testBtn addTarget:self action:@selector(testOCR) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:testBtn];
    UIButton *reload = [self btn:@"重载配置" x:222 y:50 w:104];
    [reload addTarget:self action:@selector(reloadCfg) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:reload];

    UIButton *calib = [self btn:@"校准点击" x:14 y:80 w:96];
    [calib addTarget:self action:@selector(startCalib) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:calib];
    UIButton *next = [self btn:@"换阵容" x:118 y:80 w:96];
    [next addTarget:self action:@selector(nextLineup) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:next];
    UIButton *clr = [self btn:@"清空池" x:222 y:80 w:104];
    [clr addTarget:self action:@selector(clearPool) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:clr];

    UILabel *voiceL = [[UILabel alloc] initWithFrame:CGRectMake(14, 112, 46, 18)];
    voiceL.text = @"语音"; voiceL.textColor = [UIColor colorWithWhite:0.78 alpha:1];
    voiceL.font = [UIFont systemFontOfSize:11];
    [box addSubview:voiceL];
    self.swVoice = [[UISwitch alloc] initWithFrame:CGRectMake(52, 106, 51, 31)];
    self.swVoice.transform = CGAffineTransformMakeScale(0.6, 0.6);
    self.swVoice.on = YES;
    [box addSubview:self.swVoice];

    UILabel *autoL = [[UILabel alloc] initWithFrame:CGRectMake(118, 112, 90, 18)];
    autoL.text = @"自动点击"; autoL.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    autoL.font = [UIFont systemFontOfSize:11];
    [box addSubview:autoL];
    self.swAuto = [[UISwitch alloc] initWithFrame:CGRectMake(196, 106, 51, 31)];
    self.swAuto.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [box addSubview:self.swAuto];
#if !TFT_JAILBREAK
    self.swAuto.enabled = NO;
    autoL.text = @"自动点击(需越狱)";
    autoL.textColor = [UIColor colorWithWhite:0.38 alpha:1];
#endif

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(12, 140, 316, 252)];
    tv.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    tv.textColor = [UIColor colorWithWhite:0.94 alpha:1];
    tv.font = [UIFont fontWithName:@"Menlo" size:10.5] ?: [UIFont systemFontOfSize:10.5];
    tv.editable = NO; tv.layer.cornerRadius = 10;
    tv.text = @"林森制作 · 只读画面，不改任何数据\n\n1) 点「开始识别」→ 允许屏幕录制\n2) 点「测试识别」看能否读到字\n3) 「—」收成小球，点小球回来";
    [box addSubview:tv];
    self.logView = tv;

    UIButton *bubble = [UIButton buttonWithType:UIButtonTypeCustom];
    bubble.frame = CGRectMake(0, 0, 60, 60);
    bubble.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.94];
    bubble.layer.cornerRadius = 30; bubble.layer.masksToBounds = YES;
    bubble.layer.borderWidth = 1.5;
    bubble.layer.borderColor = [UIColor colorWithRed:0.2 green:0.75 blue:1 alpha:1].CGColor;
    [bubble setTitle:@"林" forState:UIControlStateNormal];
    [bubble setTitleColor:[UIColor colorWithRed:0.2 green:0.75 blue:1 alpha:1] forState:UIControlStateNormal];
    bubble.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    bubble.hidden = YES;
    [bubble addTarget:self action:@selector(expand) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:bubble];
    self.bubble = bubble;
    [bubble addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)]];

    [root bringSubviewToFront:container];
    [self updateStatus];
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
        if (!s.forceFrame && now - s.lastTick < 0.5) return;
        s.forceFrame = NO;
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

- (void)loadHexCatalog {
    NSMutableArray *names = [NSMutableArray array];
    NSMutableDictionary *lv = [NSMutableDictionary dictionary];
    NSString *cat = [NSString stringWithUTF8String:tft_hex_catalog];
    for (NSString *pair in [cat componentsSeparatedByString:@";"]) {
        NSArray *kv = [pair componentsSeparatedByString:@"|"];
        if (kv.count < 2) continue;
        NSString *nm = (NSString *)kv[0];
        if (!nm.length) continue;
        [names addObject:nm];
        lv[nm] = @([(NSString *)kv[1] integerValue]);
    }
    [names sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        if (a.length != b.length) return a.length > b.length ? NSOrderedAscending : NSOrderedDescending;
        return [a compare:b];
    }];
    self.hexNames = names;
    self.hexLevel = lv;
    TFTWriteLog(@"hex catalog: %lu", (unsigned long)names.count);
}

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

    self.lastLineCount = (NSInteger)obs.count;

    if (self.dumpNext) {
        self.dumpNext = NO;
        NSMutableArray *ls = [NSMutableArray array];
        for (NSDictionary *o in obs) { NSString *t = o[@"t"]; if (t.length) [ls addObject:t]; }
        NSString *joined = [ls componentsJoinedByString:@" | "];
        if (joined.length > 400) joined = [joined substringToIndex:400];
        [self log:@"识别到 %lu 行: %@", (unsigned long)ls.count, joined.length ? joined : @"(空)"];
    }

    /* --- 海克斯推荐 --- */
    if (!self.hexNames.count) [self loadHexCatalog];
    NSMutableArray *hexHits = [NSMutableArray array];
    for (NSString *n in self.hexNames) {
        if ([all rangeOfString:n].location != NSNotFound) {
            [hexHits addObject:n];
            if (hexHits.count >= 6) break;
        }
    }
    if (hexHits.count) {
        NSDictionary *lvl = self.hexLevel;
        [hexHits sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
            return [lvl[b] compare:lvl[a]];
        }];
        NSMutableArray *parts = [NSMutableArray array];
        for (NSString *n in hexHits) [parts addObject:[NSString stringWithFormat:@"%@(%@)", n, self.hexLevel[n]]];
        NSString *had = [NSString stringWithFormat:@"海克斯: %@", [parts componentsJoinedByString:@" > "]];
        if (![had isEqualToString:self.lastHexAdvice ?: @""]) {
            self.lastHexAdvice = had;
            [self log:@"%@", had];
            [self speak:[NSString stringWithFormat:@"选 %@", hexHits.firstObject]];
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
    [self updateStatus];

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
