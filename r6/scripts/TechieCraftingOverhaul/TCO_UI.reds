// ============================================================================
// TCO - UI 표시
//   레플리카 아이템 이름에 " (레플리카)" / " (Replica)" 접미사를 붙인다.
//   (인벤토리/툴팁은 UIItemsHelper.GetItemName, 제작 목록은 CraftingSystem.GetRecipeData 를 쓴다)
// ============================================================================

@wrapMethod(UIItemsHelper)
public final static func GetItemName(itemRecord: ref<Item_Record>, itemData: wref<gameItemData>) -> String {
  let name = wrappedMethod(itemRecord, itemData);
  if IsDefined(itemRecord) && itemRecord.TagsContains(n"TCO_Replica") {
    name += TCO_Text.ReplicaSuffix(GetGameInstance());
  }
  return name;
}

@wrapMethod(CraftingSystem)
public final const func GetRecipeData(itemRecord: ref<Item_Record>) -> ref<RecipeData> {
  let data = wrappedMethod(itemRecord);
  if IsDefined(data) && IsDefined(itemRecord) && itemRecord.TagsContains(n"TCO_Replica") {
    data.label += TCO_Text.ReplicaSuffix(this.GetGameInstance());
  }
  return data;
}

// ---------------------------------------------------------------------------
// 제작 패널 재료 표시: 레플리카 레시피의 기반 무기
//   바닐라 재료 영역에는 무기 재료 칸이 하나뿐이라 (m_ingredientWeaponController) 기반 무기가 둘 이상이면
//   마지막 무기만 보인다 (말로리안 3516 = 타마유라 + 오버추어 → 오버추어만 표시).
//   레플리카 레시피에서는 마지막 무기를 그 칸에 두고, 나머지 무기는 일반 재료 줄로 되살려 표시한다.
//   보유 판정은 바닐라의 레코드 일치(HasItem) 대신 모델 일치 수량(GetItemCraftingCost 후킹의 inventoryQuantity)을 쓴다.
// ---------------------------------------------------------------------------
@wrapMethod(CraftingLogicController)
private final func SetupIngredients(ingredient: script_ref<array<IngredientData>>, itemAmount: Int32) -> Void {
  wrappedMethod(ingredient, itemAmount);
  if !IsDefined(this.m_selectedItemGameData) || !this.m_selectedItemGameData.HasTag(n"TCO_Replica") {
    return;
  }
  let list = Deref(ingredient);
  let lastWeapon = -1;
  let i = 0;
  while i < ArraySize(list) {
    if IsDefined(list[i].id) && RPGManager.IsItemWeapon(ItemID.CreateQuery(list[i].id.GetID())) {
      lastWeapon = i;
    }
    i += 1;
  }
  i = 0;
  while i < ArraySize(list) {
    if IsDefined(list[i].id) && RPGManager.IsItemWeapon(ItemID.CreateQuery(list[i].id.GetID())) {
      if i == lastWeapon && list[i].quantity <= 1 {
        let state = n"Unavailable";
        if list[i].inventoryQuantity >= list[i].quantity {
          state = n"Default";
        }
        this.m_ingredientWeaponController.GetRootWidget().SetState(state);
      } else {
        // 수량이 2 이상인 무기(원본 여러 개를 합치는 프리셋 등)는 개수가 보이도록 일반 줄로 표시하고 무기 칸은 감춘다
        if i == lastWeapon {
          inkCompoundRef.SetVisible(this.m_ingredientsWeaponContainer, false);
        }
        if i < ArraySize(this.m_ingredientsControllerList) && IsDefined(this.m_ingredientsControllerList[i]) {
          let data = list[i];
          this.m_ingredientsControllerList[i].SetupData(data, this.m_tooltipsManager, itemAmount);
          this.m_ingredientsControllerList[i].TCO_SetWeaponIcon(list[i].id.GetID());
        }
      }
    }
    i += 1;
  }
}

// 일반 재료 줄에 무기 아이콘을 넣는다. 무기 레코드에는 iconPath 가 없으므로 인벤토리와 같은 해석기를 쓴다.
@addMethod(IngredientListItemLogicController)
public final func TCO_SetWeaponIcon(itemID: TweakDBID) -> Void {
  let iconName = IconsNameResolver.GetIconsNameResolver().TranslateItemToIconName(itemID, false);
  if IsNameValid(iconName) {
    InkImageUtils.RequestSetImage(this, this.m_icon, "UIIcon." + NameToString(iconName));
  }
}
