// ============================================================================
// TCO - 특전 이름/설명 현지화 (Codeware Localization)
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
  }
}
