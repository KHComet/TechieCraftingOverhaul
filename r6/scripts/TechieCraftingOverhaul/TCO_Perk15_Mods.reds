// ============================================================================
// TCO - 15 특전 "Should've Been Removable" (빠지게 만들었어야지)
//   1) 개조부품 자유 탈착: UI 의 탈착 판정(RPGManager.CanPartBeUnequipped) 을 열어 준다.
//      탈착은 바닐라 RemoveItemPart 경로를 그대로 타며, 이 경로는 부품을 인벤토리로 돌려준다.
//   2) 교체 시 손실 방지: ItemModificationSystem.InstallItemPart 는 교체된 개조부품을
//      파괴(RemoveItem)하므로, 파괴된 만큼 같은 레코드의 부품을 돌려준다.
//   3) 일반 무기의 "빈 슬롯 없음" 차단을 특전 활성 시 해제한다 (인벤토리 UI 2곳).
//   4) 분해 시 회수: 분해 결과 계산(GetDisassemblyResultItems) 에 개조부품을 회수 목록으로 추가한다.
//      20 특전의 기반 무기 소모도 같은 헬퍼(TCO_CollectRetrievableParts)를 쓴다.
// ============================================================================

// 1) 탈착 판정 -------------------------------------------------------------
@wrapMethod(RPGManager)
public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
  if TCO_IsPerkActive(TCO_Perk.Removable15) && RPGManager.IsWeaponMod(RPGManager.GetItemType(data.ID)) {
    return true;
  }
  return wrappedMethod(data, slotId);
}

// 2) 교체 시 기존 부품 보존 ----------------------------------------------------
@wrapMethod(ItemModificationSystem)
private final func InstallItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, opt slotID: TweakDBID) -> Bool {
  let previousPartID: ItemID;
  let previousQuantity: Int32 = 0;
  let shouldRestore = false;
  if IsDefined(obj) && TCO_IsPerkActive(TCO_Perk.Removable15) {
    let ts = GameInstance.GetTransactionSystem(obj.GetGame());
    let resolvedSlot = slotID;
    if !IsDefined(TweakDBInterface.GetAttachmentSlotRecord(resolvedSlot)) {
      resolvedSlot = EquipmentSystem.GetPlacementSlot(partItemID);
    }
    let itemData = ts.GetItemData(obj, itemID);
    if IsDefined(itemData) && itemData.HasPartInSlot(resolvedSlot) {
      let part: InnerItemData;
      itemData.GetItemPart(part, resolvedSlot);
      previousPartID = InnerItemData.GetItemID(part);
      let previousRecord = InnerItemData.GetStaticData(part);
      if ItemID.IsValid(previousPartID)
        && RPGManager.IsWeaponMod(previousPartID)
        && IsDefined(previousRecord)
        && !previousRecord.TagsContains(n"DummyPart")
        && !previousRecord.TagsContains(n"parentPart") {
        shouldRestore = true;
        previousQuantity = ts.GetItemQuantity(obj, previousPartID);
      }
    }
  }
  let result = wrappedMethod(obj, itemID, partItemID, slotID);
  if result && shouldRestore {
    let ts = GameInstance.GetTransactionSystem(obj.GetGame());
    // 바닐라는 교체된 부품을 인벤토리로 뺀 뒤 바로 파괴한다 (수량 변화 0). 파괴된 경우에만 돌려준다.
    if ts.GetItemQuantity(obj, previousPartID) <= previousQuantity {
      ts.GiveItemByTDBID(obj, ItemID.GetTDBID(previousPartID), 1);
      TCO_Log("Restored replaced weapon mod " + TDBID.ToStringDEBUG(ItemID.GetTDBID(previousPartID)));
    }
  }
  return result;
}

// 3) 인벤토리 UI: 일반 무기에서도 개조부품 교체 허용 --------------------------------
@wrapMethod(InventoryItemModeLogicController)
private final func EquipPart(itemData: script_ref<InventoryItemData>, slotID: TweakDBID) -> Void {
  if TCO_IsPerkActive(TCO_Perk.Removable15) && IsDefined(this.m_InventoryManager) && this.m_InventoryManager.CanInstallPart(itemData) {
    let equippedItemData = this.m_selectedItemChooser.GetModifiedItemData();
    let localEquippedData = InventoryItemData.GetGameItemData(equippedItemData);
    let modItemType = InventoryItemData.GetItemType(itemData);
    if IsDefined(localEquippedData) && localEquippedData.HasPartInSlot(slotID) && RPGManager.IsWeaponMod(modItemType) {
      // 바닐라: 일반 무기 -> "빈 슬롯 없음" 알림, 아이코닉 -> 파괴 경고 팝업. 특전 활성 시 바로 교체(기존 부품은 2) 에서 복구).
      this.m_InventoryManager.InstallPart(InventoryItemData.GetID(equippedItemData), InventoryItemData.GetID(itemData), slotID);
      this.TelemetryLogPartInstalled(equippedItemData, itemData, slotID);
      this.SetPingTutorialFact(InventoryItemData.GetID(itemData), false);
      return;
    }
  }
  wrappedMethod(itemData, slotID);
}

@wrapMethod(InventoryItemModeLogicController)
private final func HandleItemClick(itemData: script_ref<InventoryItemData>, actionName: ref<inkActionName>, opt displayContext: ItemDisplayContext, opt isPlayerLocked: Bool) -> Void {
  if TCO_IsPerkActive(TCO_Perk.Removable15)
    && actionName.IsAction(n"click")
    && NotEquals(displayContext, ItemDisplayContext.Attachment)
    && !InventoryItemData.IsEquipped(itemData)
    && !InventoryItemData.IsEmpty(itemData)
    && RPGManager.IsWeaponMod(InventoryItemData.GetItemType(itemData))
    && IsDefined(this.m_selectedItemChooser) {
    let localEquippedData = InventoryItemData.GetGameItemData(this.m_selectedItemChooser.GetModifiedItemData());
    if IsDefined(localEquippedData)
      && localEquippedData.HasPartInSlot(this.m_selectedItemChooser.GetSelectedSlotID())
      && !localEquippedData.HasTag(n"IconicWeapon") {
      // 바닐라는 여기서 InventoryNoFreeSlot 알림을 띄우고 중단한다. 특전 활성 시 바닐라의 장착 흐름을 그대로 이어간다.
      if localEquippedData.HasTag(n"UnequipBlocked") || !InventoryGPRestrictionHelper.CanEquip(itemData, this.m_player) {
        this.ShowNotification(this.m_player.GetGame(), this.DetermineUIMenuNotificationType());
        return;
      }
      this.EquipItem(itemData, this.m_selectedItemChooser.GetSlotIndex());
      this.m_inventoryController.HandleCyberwareStyleUpdate(InventoryItemData.GetEquipmentArea(itemData), Deref(itemData).SlotID, true);
      if IsDefined(this.m_leftItemChooser) {
        this.m_leftItemChooser.RefreshItems(true, -1);
      }
      this.itemChooser.RefreshItems(true, -1);
      this.NotifyItemUpdate();
      return;
    }
  }
  wrappedMethod(itemData, actionName, displayContext, isPlayerLocked);
}

// 4) 분해 시 개조부품 회수 ------------------------------------------------------
@wrapMethod(CraftingSystem)
public final const func GetDisassemblyResultItems(target: wref<GameObject>, itemID: ItemID, amount: Int32, restoredAttachments: script_ref<array<ItemAttachments>>, opt calledFromUI: Bool) -> array<IngredientData> {
  let result = wrappedMethod(target, itemID, amount, restoredAttachments, calledFromUI);
  if TCO_IsPerkActive(TCO_Perk.Removable15) {
    let itemData = GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemData(target, itemID);
    if TCO_IsWeaponItem(itemData) {
      TCO_CollectRetrievableParts(itemData, restoredAttachments);
    }
  }
  return result;
}
