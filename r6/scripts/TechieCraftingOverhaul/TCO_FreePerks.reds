// ============================================================================
// TCO - 포인트 없이 자동 해금 (perkFreeUnlock)
//   특전 노드는 테크 트리에 그대로 두고, 테크 능력치가 티어 요구치(9 / 15 / 20)에 도달하면 포인트 소모 없이 구매 처리한다.
//   실제 지급/회수 로직은 TechieCraftingOverhaul.SyncFreePerks (TCO_Core.reds) 에 있고, 이 파일은 바닐라 쪽 연결만 한다.
//
//   바닐라 근거 (PlayerDevelopmentData):
//     - BuyNewPerk(perkType, forceBuy = true) 는 포인트 잔량/선행 특전 검사를 건너뛰고 포인트를 차감하지 않는다.
//     - 특전을 팔 때(직접 환불, 속성 초기화, Perk Addition Framework 의 초기화 보정 모두)
//       HandleRemovingPerkLevel 이 ReturnDevelopmentPointForSoldPerk 로 포인트 1 을 무조건 돌려준다.
//       공짜로 받은 특전까지 환불되면 "해금 -> 초기화"로 포인트가 무한히 늘어나므로, 공짜 특전만 환불을 막는다.
//     - 속성 값은 구매/초기화/콘솔 등 모든 경로가 SetAttribute 를 거쳐 바뀐다.
// ============================================================================

// 세션이 완전히 올라온 뒤 동기화를 허용한다 (TechieCraftingOverhaul.OnPlayerAttach 가 예약)
public class TCO_ReadyCallback extends DelayCallback {
  public let system: wref<TechieCraftingOverhaul>;

  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.OnSessionReady();
    }
  }
}

// 테크 능력치가 바뀌면 자동 해금 상태를 다시 맞춘다.
@wrapMethod(PlayerDevelopmentData)
public final const func SetAttribute(type: gamedataStatType, amount: Float) -> Void {
  wrappedMethod(type, amount);
  if IsDefined(this.m_owner as PlayerPuppet) {
    let sys = TechieCraftingOverhaul.GetInstance(this.m_owner.GetGame());
    if IsDefined(sys) {
      sys.SyncFreePerks();
    }
  }
}

// 공짜로 지급한 특전은 팔려도 포인트를 돌려주지 않는다. 포인트를 내고 산 특전은 바닐라대로 환불된다.
@wrapMethod(PlayerDevelopmentData)
private final func ReturnDevelopmentPointForSoldPerk(i: Int32, j: Int32) -> Void {
  if IsDefined(this.m_owner) {
    let sys = TechieCraftingOverhaul.GetInstance(this.m_owner.GetGame());
    if IsDefined(sys) && sys.ConsumeFreePerkFlag(this.m_attributesData[i].unlockedPerks[j].type) {
      return;
    }
  }
  wrappedMethod(i, j);
}

// 자동 해금이 켜져 있는 동안에는 공짜 특전을 특전 화면에서 직접 되팔 수 없다 (팔아도 즉시 다시 지급되므로).
// 속성 초기화는 ForceSellNewPerk 를 쓰므로 이 차단과 무관하게 동작한다.
@wrapMethod(PlayerDevelopmentData)
public final func SellNewPerk(perkType: gamedataNewPerkType, out perkLevelSold: Int32) -> Bool {
  if IsDefined(this.m_owner) {
    let sys = TechieCraftingOverhaul.GetInstance(this.m_owner.GetGame());
    if IsDefined(sys) && sys.IsFreeUnlockActive() && sys.IsFreePerk(perkType) {
      perkLevelSold = 0;
      return false;
    }
  }
  return wrappedMethod(perkType, perkLevelSold);
}
