// ============================================================================
// TCO - 9 특전 "If Johnny Were a Techie..." (테키 실버핸드)
//   일반 무기를 분해하면 그 무기 모델의 레시피를 "분해한 무기와 같은 티어"로 제작 목록에 추가한다
//   (TCO.Config.recipeTierMode: equal / upto / all).
//   티어별 레코드는 TCO_Tweaks.reds 가 로딩 시 생성하고, 각 프리셋 레코드에
//   ".TCO_model" / 모델 레코드에 ".TCO_tiers" flat 으로 연결해 둔다.
// ============================================================================

// 분해 요청 처리 직전에 무기 정보를 잡아두고, 분해가 끝난 뒤 레시피를 습득한다.
@wrapMethod(CraftingSystem)
private final func OnDisassembleItemRequest(request: ref<DisassembleItemRequest>) -> Void {
  let gi = this.GetGameInstance();
  let learnFrom: TweakDBID = TDBID.None();
  let learnTier: Int32 = 0;
  let sys = TechieCraftingOverhaul.GetInstance(gi);
  if IsDefined(sys) && sys.IsPerkActive(TCO_Perk.Techie9) {
    let itemData = GameInstance.GetTransactionSystem(gi).GetItemData(request.target, request.itemID);
    if IsDefined(itemData)
      && TCO_IsLearnableWeapon(itemData)
      && this.CanItemBeDisassembled(request.target, request.itemID) {
      learnFrom = ItemID.GetTDBID(request.itemID);
      learnTier = RoundF(TCO_GetEffectiveTier(itemData));
    }
  }
  wrappedMethod(request);
  if TDBID.IsValid(learnFrom) {
    sys.LearnRecipesFromWeapon(learnFrom, learnTier);
  }
}
