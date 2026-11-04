// ============================================================================
// TCO - 20 특전 "Detail Rigging" (계획된 개조)
//   원본 아이코닉(티어5+)을 분석해 기반 무기(티어5+)를 아이코닉으로 개조한다.
//   - 레플리카 레코드 (<아이코닉>_TCO_Replica) 는 TCO_Tweaks.reds 가 로딩 시 생성
//   - 조건을 만족하는 원본을 소지하면 제작 목록에 레플리카 레시피가 나타난다
//   - 제작 시 기반 무기는 "분해 판정"으로 소모(개조부품 회수) 되고, 원본은 유지된다
//   - 무기 종류당 평생 1회 (세이브에 기록, 레플리카를 분해해도 초기화되지 않음)
// ============================================================================

// ---------------------------------------------------------------------------
// CraftingSystem 후킹
// ---------------------------------------------------------------------------

// 제작 메뉴가 목록을 읽을 때마다 레플리카 레시피를 동기화한다.
@wrapMethod(CraftingSystem)
public final const func GetPlayerCraftableItems() -> array<wref<Item_Record>> {
  let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
  if IsDefined(sys) {
    sys.SyncReplicaRecipes();
  }
  return wrappedMethod();
}

// 제작 가능 판정 (목록 항목용)
@wrapMethod(CraftingSystem)
public final const func CanItemBeCrafted(itemRecord: wref<Item_Record>) -> Bool {
  let result = wrappedMethod(itemRecord);
  if result && IsDefined(itemRecord) && itemRecord.TagsContains(n"TCO_Replica") {
    let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
    result = IsDefined(sys) && sys.CanCraftReplica(itemRecord.GetID());
  }
  return result;
}

// 제작 가능 판정 (선택 항목용)
@wrapMethod(CraftingSystem)
public final const func CanItemBeCrafted(itemData: wref<gameItemData>) -> Bool {
  let result = wrappedMethod(itemData);
  if result && IsDefined(itemData) && itemData.HasTag(n"TCO_Replica") {
    let sys = TechieCraftingOverhaul.GetInstance(this.GetGameInstance());
    result = IsDefined(sys) && sys.CanCraftReplica(ItemID.GetTDBID(itemData.GetID()));
  }
  return result;
}

// 레플리카는 아이코닉 태그가 있어도 분해할 수 있다 (설정으로 끌 수 있음)
@wrapMethod(CraftingSystem)
public final const func CanItemBeDisassembled(itemData: wref<gameItemData>) -> Bool {
  if IsDefined(itemData) && itemData.HasTag(n"TCO_Replica") && TCO_Config.ReplicaDisassembleAllowed() {
    return !itemData.HasTag(n"Quest")
      && !itemData.HasTag(n"UnequipBlocked")
      && IsDefined(ItemActionsHelper.GetDisassembleAction(itemData.GetID()));
  }
  return wrappedMethod(itemData);
}

// 레플리카 제작은 바닐라 CraftItem 대신 전용 흐름으로 처리한다
@wrapMethod(CraftingSystem)
private final func OnCraftItemRequest(request: ref<CraftItemRequest>) -> Void {
  if IsDefined(request.itemRecord) && request.itemRecord.TagsContains(n"TCO_Replica") {
    let crafted = this.TCO_CraftReplica(request.target, request.itemRecord);
    if IsDefined(crafted) {
      this.UpdateBlackboard(CraftingCommands.CraftingFinished, crafted.GetID());
    } else {
      TCO_Notify(this.GetGameInstance(), TCO_Text.ReplicaFailed(this.GetGameInstance()));
      this.UpdateBlackboard(CraftingCommands.Failed);
    }
    return;
  }
  wrappedMethod(request);
}

@addMethod(CraftingSystem)
private final func TCO_CraftReplica(target: wref<GameObject>, replicaRecord: ref<Item_Record>) -> wref<gameItemData> {
  let gi = this.GetGameInstance();
  let sys = TechieCraftingOverhaul.GetInstance(gi);
  let ts = GameInstance.GetTransactionSystem(gi);
  let statsSystem = GameInstance.GetStatsSystem(gi);
  if !IsDefined(sys) || !IsDefined(target) || !IsDefined(replicaRecord) { return null; }
  let replicaID = replicaRecord.GetID();
  if !sys.CanCraftReplica(replicaID) { return null; }

  // 1. 원본 / 기반 무기 인스턴스 선정
  let originalID = TweakDBInterface.GetForeignKey(replicaID + t".TCO_original", TDBID.None());
  let originalItem = sys.FindOwnedOriginal(originalID);
  let originalData = ts.GetItemData(target, originalItem);
  let bases = TweakDBInterface.GetForeignKeyArray(replicaID + t".TCO_bases");
  let chosen: array<ItemID>;
  ArrayPush(chosen, originalItem);
  for baseID in bases {
    let instance = sys.FindBaseInstance(baseID, chosen);
    if !ItemID.IsValid(instance) { return null; }
    ArrayPush(chosen, instance);
  }

  // 2. 부품 검사 (레시피 재료 중 무기가 아닌 것)
  let ingredients = this.GetItemCraftingCost(replicaRecord);
  if !this.HasIngredients(ingredients) { return null; }

  // 3. 기반 무기 소모 = 분해 판정 (장착 부품 회수 후 제거)
  let i = 1;
  while i < ArraySize(chosen) {
    let baseItemID = chosen[i];
    let baseData = ts.GetItemData(target, baseItemID);
    let restored: array<ItemAttachments>;
    TCO_CollectRetrievableParts(baseData, restored);
    for attachment in restored {
      ts.RemovePart(target, baseItemID, attachment.attachmentSlotID);
    }
    GameInstance.GetTelemetrySystem(gi).LogItemDisassembled(target, baseItemID);
    ts.RemoveItem(target, baseItemID, 1);
    i += 1;
  }

  // 4. 부품 소모 + 제작 경험치
  let recipeXP = 0;
  for ingredient in ingredients {
    let ingredientID = ingredient.id.GetID();
    if !RPGManager.IsItemWeapon(ItemID.CreateQuery(ingredientID)) {
      ts.RemoveItemByTDBID(target, ingredientID, ingredient.quantity, true);
      recipeXP += TCO_IngredientXP(ingredient.id) * ingredient.baseQuantity;
    }
  }

  // 5. 레플리카 지급, 레벨/제작 표시, 원본과 티어 일치
  let craftedItemID = ItemID.FromTDBID(replicaID);
  ts.GiveItem(target, craftedItemID, 1);
  let craftedData = ts.GetItemData(target, craftedItemID);
  if !IsDefined(craftedData) { return null; }
  this.SetItemLevel(craftedData);
  this.MarkItemAsCrafted(craftedData);
  TCO_MatchTier(statsSystem, originalData, craftedData);

  // 6. 복제 기록, 레시피 숨김, 통계/경험치/알림
  sys.MarkCloned(originalID);
  this.GetPlayerCraftBook().HideRecipe(replicaID, true);
  this.SendItemCraftedDataTrackingRequest(craftedItemID, 1);
  this.ProcessCraftSkill(Cast<Float>(recipeXP));
  TCO_Notify(gi, TCO_Text.ReplicaCrafted(gi, TCO_ItemName(replicaRecord)));
  TCO_Log("Replica crafted: " + TDBID.ToStringDEBUG(replicaID) + " (cloned types: " + IntToString(sys.GetClonedCount()) + ")");
  return craftedData;
}
