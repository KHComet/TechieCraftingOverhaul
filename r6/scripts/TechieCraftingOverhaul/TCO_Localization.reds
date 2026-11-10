// ============================================================================
// TCO - 특전 이름/설명, Mod Settings 메뉴 라벨 현지화 (Codeware Localization)
//   Codeware 가 등록한 키는 TweakDB 의 LocKey#TCO-... 로도 풀립니다.
// ============================================================================
module TCO.Localization
import Codeware.Localization.*

public class TCO_LocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      case n"kr-kr": return new TCO_Korean();
      case n"en-us": return new TCO_English();
      default: return null;
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class TCO_English extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.Text("TCO-Perk9-Name", "If Johnny Were a Techie...");
    this.Text("TCO-Perk9-Desc", "Disassembling a weapon teaches you its crafting spec at the same tier as the weapon you took apart.\n\nYeah, you rip off the corps' off-the-shelf shit and make it yours. That's what rebellion is. If I'd been a techie, holed up in some back room all day tinkering with a wrench and jerking off, this is exactly how I would've screwed the corps.");
    this.Text("TCO-Perk15-Name", "Should've Been Removable");
    this.Text("TCO-Perk15-Desc", "Weapon mods can be swapped however you like. Disassembling a weapon returns the mods attached to it.\nThis perk requires a higher Technical Ability. (Required: 15)\n\nYeah. A couple of knocks with whatever's lying around and it pops right out. That's what a 'mod' is supposed to be. So why'd the corpo fucks make it stick? Simple. So they can slip one of their ninjas into your account and bleed you dry. Would've been a hell of a lot easier if the damn thing just came out, wouldn't it? For you. And for me.");
    this.Text("TCO-Perk20-Name", "Detail Rigging");
    this.Text("TCO-Perk20-Desc", "Craft a replica of an iconic weapon you own, only once per weapon. Only iconic weapons of Tier 5 or higher can be replicated, and you need the unmodified base weapon to work on. Some weapons call for a different base weapon.\nThis perk requires a higher Technical Ability. (Required: 20)\n\nStreet techies get by on jury-rigged fixes done on the spot. But a techie at your level? You draw up a plan before you ever touch the detail work. Militech R&D might start keeping an eye on you, V. When they do, tell 'em to fuck off. Loud and proud.");
    // Mod Settings 메뉴 라벨 (TCO_Settings.reds)
    this.Text("TCO-Settings-Cat-Perks", "Perks");
    this.Text("TCO-Settings-Cat-Recipes", "If Johnny Were a Techie... (9)");
    this.Text("TCO-Settings-Cat-Replica", "Detail Rigging (20)");
    this.Text("TCO-Settings-Cat-Misc", "Misc");
    this.Text("TCO-Settings-Perk9Enabled", "If Johnny Were a Techie...");
    this.Text("TCO-Settings-Perk15Enabled", "Should've Been Removable");
    this.Text("TCO-Settings-Perk20Enabled", "Detail Rigging");
    this.Text("TCO-Settings-PerkEnabled-Desc", "When off, the perk has no effect even if you own it.");
    this.Text("TCO-Settings-PerkFreeUnlock", "Unlock without perk points");
    this.Text("TCO-Settings-PerkFreeUnlock-Desc", "The three perks unlock by themselves when Technical Ability reaches 9 / 15 / 20 and cost no perk points. Points already spent on them are refunded. Turning this off takes the free perks back.");
    this.Text("TCO-Settings-Perk9Attribute", "Tech required: If Johnny Were a Techie...");
    this.Text("TCO-Settings-Perk15Attribute", "Tech required: Should've Been Removable");
    this.Text("TCO-Settings-Perk20Attribute", "Tech required: Detail Rigging");
    this.Text("TCO-Settings-PerkAttribute-Desc", "Only used when the perks are not tree nodes (Perk Addition Framework missing, or perkMode set to attribute). Tree nodes always use 9 / 15 / 20.");
    this.Text("TCO-Settings-RecipeTiers", "Spec tiers learned");
    this.Text("TCO-Settings-RecipeTiers-Desc", "Which tiers you learn when you disassemble a weapon.");
    this.Text("TCO-Settings-RecipeTiers-Equal", "Same tier as the weapon");
    this.Text("TCO-Settings-RecipeTiers-UpTo", "That tier and below");
    this.Text("TCO-Settings-RecipeTiers-All", "All tiers");
    this.Text("TCO-Settings-ReplicaPreset", "Replica cost");
    this.Text("TCO-Settings-ReplicaPreset-Desc", "What a replica costs. Weapons with their own cost override in the YAML files are not affected.");
    this.Text("TCO-Settings-Preset-Base", "Base weapon + components");
    this.Text("TCO-Settings-Preset-Parts", "Components only");
    this.Text("TCO-Settings-Preset-Fusion", "Two extra originals");
    this.Text("TCO-Settings-Preset-Custom", "Custom");
    this.Text("TCO-Settings-ReplicaMaterialAmount", "Component amount");
    this.Text("TCO-Settings-ReplicaMaterialAmount-Desc", "Tier 5 components per replica. Not used by the 'Two extra originals' cost.");
    this.Text("TCO-Settings-ReplicaUseBaseWeapon", "Custom: require base weapon");
    this.Text("TCO-Settings-ReplicaOriginalCopies", "Custom: extra originals consumed");
    this.Text("TCO-Settings-CustomOnly-Desc", "Only used when the replica cost is set to Custom.");
    this.Text("TCO-Settings-ReplicaRequiredTier", "Minimum tier");
    this.Text("TCO-Settings-ReplicaRequiredTier-Desc", "Lowest tier the original iconic and the base weapon must have.");
    this.Text("TCO-Settings-Tier-5", "Tier 5");
    this.Text("TCO-Settings-Tier-5Plus", "Tier 5+");
    this.Text("TCO-Settings-Tier-5PlusPlus", "Tier 5++");
    this.Text("TCO-Settings-ReplicaDisassemble", "Allow disassembling replicas");
    this.Text("TCO-Settings-ReplicaDisassemble-Desc", "Iconic weapons cannot be disassembled. Turn this on to make replicas the exception.");
    this.Text("TCO-Settings-Notifications", "On-screen notifications");
    this.Text("TCO-Settings-Notifications-Desc", "Show a message when a spec is learned or a replica is crafted.");
    this.Text("TCO-Settings-DebugLog", "Debug messages");
    this.Text("TCO-Settings-DebugLog-Desc", "Show why a spec was skipped and what the replica list found. For troubleshooting.");
  }
}

public class TCO_Korean extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.Text("TCO-Perk9-Name", "테키 실버핸드");
    this.Text("TCO-Perk9-Desc", "무기를 분해하면 분해한 무기와 같은 티어의 레시피를 획득합니다.\n\n그래, 기업이 만든 기성품을 존나 베껴서 네 거로 삼는 거야. 그게 저항 정신이지. 방구석에서 좆같은 공구만 잡고 딸딸이 치는 버전의 나라면 그렇게 했을 걸.");
    this.Text("TCO-Perk15-Name", "빠지게 만들었어야지");
    this.Text("TCO-Perk15-Desc", "개조부품을 원하는대로 바꿀 수 있습니다. 무기를 분해하면 장착된 개조부품을 돌려받습니다.\n이 특전은 더 높은 테크 능력을 요구합니다. (요구: 15)\n\n그래. 대충 공구 몇 번 땅땅 두드리면 나오는 게 정상적인 '개조'잖아. 그럼 왜 기업 새끼들이 이걸 못 빼게 만들었을까? 정답은, 네 계좌에 닌자를 심어서 돈을 훔쳐오게 만들기 위해서지. 좀 빠지게 만들었으면 얼마나 편했겠냐? 너나, 나나.");
    this.Text("TCO-Perk20-Name", "계획된 개조");
    this.Text("TCO-Perk20-Desc", "가지고 있는 신화 무기의 레플리카를 무기 당 단 한 번만 제작할 수 있습니다. 티어 5 이상의 신화무기의 레플리카만 제작할 수 있으며, 개조 전 원본 무기가 필요합니다. 일부 무기는 다른 무기를 요구합니다.\n이 특전은 더 높은 테크 능력을 요구합니다. (요구: 20)\n\n길거리 테키들은 현장에서 급조한 개조로 일을 해결하지만, 이 정도 수준이 되면 계획이라는 걸 짜고 개조할 수 있게 되지. 밀리테크 개발팀이 널 눈 여겨 볼 지도 모르겠다, V. 그 땐 당당하게 좆까라고 말하고.");
    // Mod Settings 메뉴 라벨 (TCO_Settings.reds)
    this.Text("TCO-Settings-Cat-Perks", "특전");
    this.Text("TCO-Settings-Cat-Recipes", "테키 실버핸드 (9)");
    this.Text("TCO-Settings-Cat-Replica", "계획된 개조 (20)");
    this.Text("TCO-Settings-Cat-Misc", "기타");
    this.Text("TCO-Settings-Perk9Enabled", "테키 실버핸드");
    this.Text("TCO-Settings-Perk15Enabled", "빠지게 만들었어야지");
    this.Text("TCO-Settings-Perk20Enabled", "계획된 개조");
    this.Text("TCO-Settings-PerkEnabled-Desc", "끄면 특전을 보유하고 있어도 효과가 적용되지 않습니다.");
    this.Text("TCO-Settings-PerkFreeUnlock", "포인트 없이 자동 해금");
    this.Text("TCO-Settings-PerkFreeUnlock-Desc", "테크 능력치가 9 / 15 / 20 에 도달하면 세 특전이 포인트 소모 없이 자동으로 해금됩니다. 이미 포인트로 찍은 특전은 포인트를 돌려받습니다. 끄면 공짜로 받은 특전은 회수됩니다.");
    this.Text("TCO-Settings-Perk9Attribute", "요구 테크: 테키 실버핸드");
    this.Text("TCO-Settings-Perk15Attribute", "요구 테크: 빠지게 만들었어야지");
    this.Text("TCO-Settings-Perk20Attribute", "요구 테크: 계획된 개조");
    this.Text("TCO-Settings-PerkAttribute-Desc", "특전이 트리 노드가 아닐 때만 쓰입니다(Perk Addition Framework 미설치 또는 perkMode 가 attribute). 트리 노드는 항상 9 / 15 / 20 입니다.");
    this.Text("TCO-Settings-RecipeTiers", "습득하는 레시피 티어");
    this.Text("TCO-Settings-RecipeTiers-Desc", "무기를 분해했을 때 어느 티어의 레시피를 배울지 정합니다.");
    this.Text("TCO-Settings-RecipeTiers-Equal", "분해한 무기와 같은 티어");
    this.Text("TCO-Settings-RecipeTiers-UpTo", "같은 티어 이하 전부");
    this.Text("TCO-Settings-RecipeTiers-All", "모든 티어");
    this.Text("TCO-Settings-ReplicaPreset", "레플리카 비용");
    this.Text("TCO-Settings-ReplicaPreset-Desc", "레플리카 제작에 드는 비용입니다. YAML 파일에서 비용을 따로 재정의한 무기에는 적용되지 않습니다.");
    this.Text("TCO-Settings-Preset-Base", "기반 무기 + 부품");
    this.Text("TCO-Settings-Preset-Parts", "부품만");
    this.Text("TCO-Settings-Preset-Fusion", "원본 2개 추가 소모");
    this.Text("TCO-Settings-Preset-Custom", "사용자 지정");
    this.Text("TCO-Settings-ReplicaMaterialAmount", "부품 수량");
    this.Text("TCO-Settings-ReplicaMaterialAmount-Desc", "레플리카 하나에 드는 티어 5 부품 수입니다. '원본 2개 추가 소모' 비용에서는 쓰이지 않습니다.");
    this.Text("TCO-Settings-ReplicaUseBaseWeapon", "사용자 지정: 기반 무기 요구");
    this.Text("TCO-Settings-ReplicaOriginalCopies", "사용자 지정: 원본 추가 소모 수");
    this.Text("TCO-Settings-CustomOnly-Desc", "레플리카 비용이 '사용자 지정'일 때만 적용됩니다.");
    this.Text("TCO-Settings-ReplicaRequiredTier", "최소 티어");
    this.Text("TCO-Settings-ReplicaRequiredTier-Desc", "원본 신화 무기와 기반 무기가 갖춰야 하는 최소 티어입니다.");
    this.Text("TCO-Settings-Tier-5", "티어 5");
    this.Text("TCO-Settings-Tier-5Plus", "티어 5+");
    this.Text("TCO-Settings-Tier-5PlusPlus", "티어 5++");
    this.Text("TCO-Settings-ReplicaDisassemble", "레플리카 분해 허용");
    this.Text("TCO-Settings-ReplicaDisassemble-Desc", "신화 무기는 분해할 수 없습니다. 켜면 레플리카만 예외로 분해할 수 있습니다.");
    this.Text("TCO-Settings-Notifications", "화면 알림");
    this.Text("TCO-Settings-Notifications-Desc", "레시피를 배우거나 레플리카를 제작했을 때 메시지를 표시합니다.");
    this.Text("TCO-Settings-DebugLog", "디버그 메시지");
    this.Text("TCO-Settings-DebugLog-Desc", "레시피를 건너뛴 이유와 레플리카 목록 검사 결과를 표시합니다. 문제 확인용입니다.");
  }
}
