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
