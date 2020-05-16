////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	DefineMetadataObjectsCollections();
		
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshSettings(Undefined);
		
EndProcedure // OnOpen()

#EndRegion // EventHandlers

////////////////////////////////////////////////////////////////////////////////
// ITEM EVENT HANDLERS

#Region ItemEventHandlers

#Region MetadataObjectsTree

&AtClient
Procedure MetadataObjectsTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	
	TreeItem = MetadataObjectsTree.FindByID(SelectedRow);
	
	If Not TreeItem.IsCollection Then
		
		StandardProcessing = False;
		
		ObjectInfo = MetadataObjectInfoByMetadataObjectsTreeItem(TreeItem);
				
		Collection		= MetadataObjectsCollections[ObjectInfo.ManagerName];
		FormNameToOpen	= StrTemplate(Collection.FormName, ObjectInfo.Name);
		
		OpenForm(FormNameToOpen);
	
	EndIf;
	
EndProcedure // MetadataObjectsTreeSelection()

&AtClient
Procedure MetadataObjectsTreeOnActivateRow(Item)
	
	TreeItem				= Item.CurrentData;		
	MetadataObjectTreeItem	= TreeItem <> Undefined And Not TreeItem.IsCollection;
				
	Items.GroupMetadataObjectSettings.Visible		= MetadataObjectTreeItem;
	Items.DecorationSelectMetadataObject.Visible	= Not MetadataObjectTreeItem;
	
	If TreeItem <> Undefined Then	
		Items.MetadataObjectsTreeFields.Visible = TreeItem.Fields.GetItems().Count() > 0;
	Else
		Items.MetadataObjectsTreeFields.Visible = False;
	EndIf;
		
EndProcedure // MetadataObjectsTreeOnActivateRow()

#EndRegion // MetadataObjectsTree

#Region MetadataObjectFields

&AtClient
Procedure MetadataObjectsTreeFieldsUseOnChange(Item)
	
	TreeItem = Items.MetadataObjectsTreeFields.CurrentData;
	
	If IsCheckboxPartiallyChecked(TreeItem.EnableAuditLog) Then
		MakeCheckboxNotChecked(TreeItem.EnableAuditLog);
	EndIf;	
	
	If TreeItem.IsCollection Then
		UpdateSubordinatedMetadataObjectsTreeFields(TreeItem);				
	EndIf;
		
	TreeItemParent = TreeItem.GetParent();
		
	If TreeItemParent <> Undefined Then		
		UpdateParentMetadataObjectsTreeFields(TreeItemParent);
	EndIf;
	
	SetSettingsForSelectedMetadataObject();
	
EndProcedure // MetadataObjectsTreeAttributesCheckOnChange()

&AtClient
Procedure UpdateSubordinatedMetadataObjectsTreeFields(TreeItem)
	
	TreeItemItems = TreeItem.GetItems();
	
	For Each TreeItemItem In TreeItemItems Do
		
		TreeItemItem.EnableAuditLog = TreeItem.EnableAuditLog;
		
		If TreeItemItem.IsCollection Then
			UpdateSubordinatedMetadataObjectsTreeFields(TreeItemItem);
		EndIf;
		
	EndDo;
	
EndProcedure // UpdateSubordinatedMetadataObjectsTreeFields()

&AtClient
Procedure UpdateParentMetadataObjectsTreeFields(TreeItem)
	
	TreeItemItems = TreeItem.GetItems();	
	
	UpdateTreeItemUseAccordingToSubItems(TreeItem, TreeItemItems);
	
	TreeItemParent = TreeItem.GetParent();
	
	If TreeItemParent <> Undefined Then
		UpdateParentMetadataObjectsTreeFields(TreeItemParent);
	EndIf;
	
EndProcedure // UpdateParentMetadataObjectsTreeFields()

#EndRegion // MetadataObjectAttributes	

&AtClient
Procedure MetadataObjectEnableAuditLogOnChange(Item)
	
	SetSettingsForSelectedMetadataObject();
	
EndProcedure // MetadataObjectEnableAuditLogOnChange()

&AtClient
Procedure ShowMetadataObjectNamesOnChange(Item)
	
	RefreshSettings(Undefined);
	
EndProcedure // ShowMetadataObjectNamesOnChange()

&AtClient
Procedure ShowMetadataObjectRecordsNumberOnChange(Item)
	
	RefreshSettings(Undefined);
	
EndProcedure // ShowMetadataObjectRecordsNumberOnChange()

#EndRegion // ItemEventHandlers

////////////////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS

#Region CommandHandlers

#Region RefreshSettings

&AtClient
Procedure RefreshSettings(Command)
	
	MessageText	= NStr(
		"en = 'Loading audit log settings...';
		|ru = 'Загрузка настроек истории данных...'"
	);
	
	Status(MessageText);
	
	LoadSettingsAtServer();
	
	MessageText	= NStr(
		"en = 'Loading audit log settings is completed.';
		|ru = 'Загрузка настроек истории данных завершена.'"
	);
	
	Status(MessageText);		
	
EndProcedure // RefreshSettings()

#EndRegion // RefreshSettings

#Region DeleteSettings

&AtClient
Procedure SetDefaultMetadataSettings(Command)
	
	If Items.MetadataObjectsTree.SelectedRows.Count() > 0 Then
		
		Callback	= New NotifyDescription("SetDefaultMetadataSettingsCallback", ThisObject);
		QueryText	= NStr(
			"en = 'All audit log settings for selected objects will be reset. This operation cannot be undone. Continue?';
			|ru = 'Все настройки истории данных для выделенных объектов будут сброшены. Это действие нельзя отменить. Продолжить?'"
		);
		
		ShowQueryBox(Callback, QueryText, QuestionDialogMode.YesNo);		
		
	EndIf;
	
EndProcedure // SetDefaultMetadataSettings()

&AtClient
Procedure SetDefaultMetadataSettingsCallback(ReturnCode, AdditionalParameters) Export

	If ReturnCode = DialogReturnCode.Yes Then
		
		MessageText	= NStr(
			"en = 'Resetting audit log settings...';
			|ru = 'Сброс настроек истории данных...'"
		);
		
		Status(MessageText);		
		
		SetDefaultMetadataSettingsAtServer();		
		
		MessageText	= NStr(
			"en = 'Resetting audit log settings is completed.';
			|ru = 'Сброс настроек истории данных завершен.'"
		);
		
		Status(MessageText);				
		
	EndIf;
	
EndProcedure // SetDefaultMetadataSettingsCallback()

&AtServer
Procedure SetDefaultMetadataSettingsAtServer()
		
	For Each ID In Items.MetadataObjectsTree.SelectedRows Do
		
		TreeItem = MetadataObjectsTree.FindByID(ID);
		
		SetDefaultMetadataSettingsForTreeItemAtServer(TreeItem);
		
	EndDo;
				
EndProcedure // SetDefaultMetadataSettingsAtServer()

&AtServer
Procedure SetDefaultMetadataSettingsForTreeItemAtServer(TreeItem)
	
	If TreeItem.IsCollection Then
			
		SubTreeItems = TreeItem.GetItems();
			
		For Each SubTreeItem In SubTreeItems Do								
			SetSettingsForMetadataObjectsTreeItem(SubTreeItem, Undefined);
		EndDo;
			
		InitializeMetadataObjectsTreeItemForCollection(TreeItem);
			
	Else
		
		SetSettingsForMetadataObjectsTreeItem(TreeItem, Undefined);
				
		InitializeMetadataObjectsTreeItemForCollection(TreeItem.GetParent());
			
	EndIf;	
	
EndProcedure // SetDefaultMetadataSettingsForTreeItemAtServer()

#EndRegion // DeleteSettings

&AtClient
Procedure CheckAllFields(Command)
	
	ChangeMetadataObjectFieldsUse(Items.MetadataObjectsTree.CurrentData.Fields, True);
	
	SetSettingsForSelectedMetadataObject();
	
EndProcedure // CheckAllFields()

&AtClient
Procedure UncheckAllFields(Command)
	
	ChangeMetadataObjectFieldsUse(Items.MetadataObjectsTree.CurrentData.Fields, False);
	
	SetSettingsForSelectedMetadataObject();
	
EndProcedure // UncheckAllFields()

&AtClient
Procedure ExpandAllFields(Command)
	
	ItemsToExpand = Items.MetadataObjectsTree.CurrentData.Fields.GetItems();
	
	For Each ItemToExpand In ItemsToExpand Do
		Items.MetadataObjectsTreeFields.Expand(ItemToExpand.GetID(), True);
	EndDo;
	
EndProcedure // ExpandAllFields()

&AtClient
Procedure CollapseAllFields(Command)
	
	ItemsToCollapse	= Items.MetadataObjectsTree.CurrentData.Fields.GetItems();
	
	For Each ItemToCollapse In ItemsToCollapse Do		
		Items.MetadataObjectsTreeFields.Collapse(ItemToCollapse.GetID());		
	EndDo;
	
EndProcedure // CollapseAllFields()

&AtClient
Procedure EnableAuditLog(Command)
	
	ChangeAuditLogState(True);

EndProcedure // EnableAuditLog()

&AtClient
Procedure DisableAuditLog(Command)

	ChangeAuditLogState(False);
	
EndProcedure // DisableAuditLog()

#EndRegion // CommandHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

#Region SetSettingsForSelectedMetadataObject

&AtClient
Procedure SetSettingsForSelectedMetadataObject()
	
	MessageText	= NStr(
		"en = 'Updating audit log settings...';
		|ru = 'Обновление настроек истории данных...'"
	);
		
	Status(MessageText);			
	
	SetSettingsForSelectedMetadataObjectAtServer();
	
	MessageText	= NStr(
		"en = 'Updating audit log settings is completed.';
		|ru = 'Обновление настроек истории данных завершено.'"
	);
	
	Status(MessageText);	
	
EndProcedure // SetSettingsForSelectedMetadataObject()

&AtServer
Procedure SetSettingsForSelectedMetadataObjectAtServer(TreeItemIDs = Undefined)
	
	TreeItemParents = New Map;
	
	If TreeItemIDs = Undefined Then
		
		TreeItemID = Items.MetadataObjectsTree.SelectedRows[0];
		
		TreeItemIDs = New Array;
		TreeItemIDs.Add(TreeItemID);
		
	EndIf;
	
	For Each TreeItemID In TreeItemIDs Do

		TreeItem = MetadataObjectsTree.FindByID(TreeItemID);
		
		DataHistorySettings		= New DataHistorySettings;
		DataHistorySettings.Use	= TreeItem.EnableAuditLog;
		
		FieldsTreeItems = TreeItem.Fields.GetItems();
		
		For Each FieldsTreeItem In FieldsTreeItems Do		
			FieldsTreeItemsAsFieldsUse(DataHistorySettings, FieldsTreeItem);
		EndDo;
				
		SetSettingsForMetadataObjectsTreeItem(TreeItem, DataHistorySettings);
		
		TreeItemParent = TreeItem.GetParent();		
		TreeItemParents[TreeItemParent.Name] = TreeItemParent;
		
	EndDo;
	
	For Each TreeItemParent In TreeItemParents Do	
		InitializeMetadataObjectsTreeItemForCollection(TreeItemParent.Value);	
	EndDo;
	
EndProcedure // SetSettingsForSelectedMetadataObjectAtServer()

&AtServer
Procedure FieldsTreeItemsAsFieldsUse(DataHistorySettings, TreeItem)
	
	TreeItemItems = TreeItem.GetItems();
	
	For Each TreeItemItem In TreeItemItems Do
		
		If TreeItemItem.IsCollection Then
			FieldsTreeItemsAsFieldsUse(DataHistorySettings, TreeItemItem);
		Else
			DataHistorySettings.FieldsUse[TreeItemItem.Name] = TreeItemItem.EnableAuditLog = 1;
		EndIf;
				
	EndDo;	
	
EndProcedure // FieldsTreeItemsAsFieldsUse()

&AtServer
Procedure SetSettingsForMetadataObjectsTreeItem(TreeItem, Settings)
	
	MetadataObject = MetadataObjectByMetadataObjectsTreeItem(TreeItem);
	
	Try
	
		DataHistory.SetSettings(MetadataObject, Settings);
		
		NewSettings = DataHistory.GetSettings(MetadataObject);	
	
	Except
		
		NewSettings = Undefined;
		
		Message = BriefErrorDescription(ErrorInfo());
		MessageToUser(Message);
				
	EndTry;	
	
	If Settings = Undefined Then
		
		InitializeMetadataObjectsTreeItemForObject(TreeItem, MetadataObject, NewSettings);
		
	Else	
		
		TreeItem.InfobaseSettingsPicture = PictureLib.SettingsStorage;		
		
	EndIf;
	
EndProcedure // SetSettingsForMetadataObjectsTreeItem()

#EndRegion // UpdateMetadataObjectSettings

#Region MetadataObjectsCollections

&AtServer
Procedure DefineMetadataObjectsCollections()
	
	Collections = New Structure;
		
	DefineMetadataObjectsCollectionForExchangePlans(Collections);
	DefineMetadataObjectsCollectionForConstants(Collections);
	DefineMetadataObjectsCollectionForCatalogs(Collections);
	DefineMetadataObjectsCollectionForDocuments(Collections);
	DefineMetadataObjectsCollectionForChartsOfCharacteristicTypes(Collections);
	DefineMetadataObjectsCollectionForChartsOfAccounts(Collections);
	DefineMetadataObjectsCollectionForChartsOfCalculationTypes(Collections);
	DefineMetadataObjectsCollectionForInformationRegisters(Collections);
	DefineMetadataObjectsCollectionForBusinessProcesses(Collections);
	DefineMetadataObjectsCollectionForTasks(Collections);

	MetadataObjectsCollections = New FixedStructure(Collections);
	
EndProcedure // DefineMetadataObjectsCollections()

&AtServer
Procedure DefineMetadataObjectsCollection(Collections, Collection)
	
	Collections.Insert(Collection.Name, Collection);
	
EndProcedure // DefineMetadataObjectsCollection()

&AtServer
Function MetadataObjectsCollection()
	
	Collection = New Structure;
	
	Collection.Insert("Name",				"");
	Collection.Insert("Presentation",		"");
	Collection.Insert("Picture",			Undefined);
	Collection.Insert("FormName",			"");
	Collection.Insert("HasAttributes",		False);
	Collection.Insert("HasTabularSections",	False);
	Collection.Insert("HasDimensions",		False);	
	Collection.Insert("HasResources",		False);	
	
	Return Collection;
					
EndFunction // MetadataObjectsCollection()

&AtServer
Procedure DefineMetadataObjectsCollectionForExchangePlans(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "ExchangePlans";
	Collection.Presentation	= NStr("en = 'Exchange Plans'; ru = 'Планы обмена'");
	Collection.Picture		= PictureLib.ExchangePlan;
	Collection.FormName		= "ExchangePlan.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;	
	
	DefineMetadataObjectsCollection(Collections, Collection);

EndProcedure // DefineMetadataObjectsCollectionForExchangePlans()

&AtServer
Procedure DefineMetadataObjectsCollectionForConstants(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "Constants";
	Collection.Presentation	= NStr("en = 'Constants'; ru = 'Константы'");
	Collection.Picture		= PictureLib.Constant;
	Collection.FormName		= "Constant.%1.ConstantsForm";
	
	Collection.HasAttributes		= False;
	Collection.HasTabularSections	= False;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;		
	
	DefineMetadataObjectsCollection(Collections, Collection);
		
EndProcedure // DefineMetadataObjectsCollectionForConstants()

&AtServer
Procedure DefineMetadataObjectsCollectionForCatalogs(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "Catalogs";
	Collection.Presentation	= NStr("en = 'Catalogs'; ru = 'Справочники'");
	Collection.Picture		= PictureLib.Catalog;
	Collection.FormName		= "Catalog.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);	
		
EndProcedure // DefineMetadataObjectsCollectionForCatalogs()

&AtServer
Procedure DefineMetadataObjectsCollectionForDocuments(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "Documents";
	Collection.Presentation	= NStr("en = 'Documents'; ru = 'Документы'");
	Collection.Picture		= PictureLib.Document;
	Collection.FormName		= "Document.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);		
		
EndProcedure // DefineMetadataObjectsCollectionForDocuments()

&AtServer
Procedure DefineMetadataObjectsCollectionForChartsOfCharacteristicTypes(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "ChartsOfCharacteristicTypes";
	Collection.Presentation	= NStr("en = 'Charts of Characteristic Type'; ru = 'Планы видов характеристик'");
	Collection.Picture		= PictureLib.ChartOfCharacteristicTypes;
	Collection.FormName		= "ChartOfCharacteristicTypes.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);
		
EndProcedure // DefineMetadataObjectsCollectionForChartsOfCharacteristicTypes()

&AtServer
Procedure DefineMetadataObjectsCollectionForChartsOfAccounts(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "ChartsOfAccounts";
	Collection.Presentation	= NStr("en = 'Charts of Accounts'; ru = 'Планы счетов'");
	Collection.Picture		= PictureLib.ChartOfAccounts;
	Collection.FormName		= "ChartOfAccounts.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);
	
EndProcedure // DefineMetadataObjectsCollectionForChartsOfAccounts()

&AtServer
Procedure DefineMetadataObjectsCollectionForChartsOfCalculationTypes(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "ChartsOfCalculationTypes";
	Collection.Presentation	= NStr("en = 'Charts of Calculation Types'; ru = 'Планы видов расчета'");
	Collection.Picture		= PictureLib.ChartOfCalculationTypes;
	Collection.FormName		= "ChartOfCalculationTypes.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);
		
EndProcedure // DefineMetadataObjectsCollectionForChartsOfCalculationTypes()

&AtServer
Procedure DefineMetadataObjectsCollectionForInformationRegisters(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "InformationRegisters";
	Collection.Presentation	= NStr("en = 'Information Registers'; ru = 'Регистры сведений'");
	Collection.Picture		= PictureLib.InformationRegister;
	Collection.FormName		= "InformationRegister.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= False;
	Collection.HasDimensions		= True;
	Collection.HasResources			= True;
	
	DefineMetadataObjectsCollection(Collections, Collection);
		
EndProcedure // DefineMetadataObjectsCollectionForInformationRegisters()

&AtServer
Procedure DefineMetadataObjectsCollectionForBusinessProcesses(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "BusinessProcesses";
	Collection.Presentation	= NStr("en = 'Business Processes'; ru = 'Бизнес-процессы'");
	Collection.Picture		= PictureLib.BusinessProcess;
	Collection.FormName		= "BusinessProcess.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);
		
EndProcedure // DefineMetadataObjectsCollectionForBusinessProcesses()

&AtServer
Procedure DefineMetadataObjectsCollectionForTasks(Collections)
	
	Collection = MetadataObjectsCollection();
	
	Collection.Name			= "Tasks";
	Collection.Presentation	= NStr("en = 'Tasks'; ru = 'Задачи'");
	Collection.Picture		= PictureLib.Task;
	Collection.FormName		= "Task.%1.ListForm";	
	
	Collection.HasAttributes		= True;
	Collection.HasTabularSections	= True;
	Collection.HasDimensions		= False;
	Collection.HasResources			= False;			
	
	DefineMetadataObjectsCollection(Collections, Collection);
	
EndProcedure // DefineMetadataObjectsCollectionForTasks()

&AtServer
Function MetadataObjectCollectionByMetadataObjectsTreeItem(TreeItem)
	
	ObjectInfo = MetadataObjectInfoByMetadataObjectsTreeItem(TreeItem);
	
	Return MetadataObjectsCollections[ObjectInfo.ManagerName];
		
EndFunction // MetadataObjectCollectionByMetadataObjectsTreeItem()

#EndRegion // MetadataObjectsCollections

#Region MetadataObjectsTree

&AtServer
Procedure InitializeMetadataObjectsTreeItemForCollection(TreeItem)
	
	MetadataObjectItems		= TreeItem.GetItems();	
	TreeItem.EnableAuditLog	= False;
	
	For Each MetadataObjectItem In MetadataObjectItems Do
		
		If MetadataObjectItem.EnableAuditLog Then
			
			TreeItem.EnableAuditLog = True;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure // InitializeMetadataObjectsTreeItemForCollection()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObject(TreeItem, MetadataObject, DataHistorySettings)
			
	If DataHistorySettings <> Undefined Then
		
		TreeItem.EnableAuditLog				= DataHistorySettings.Use;
		TreeItem.InfobaseSettingsPicture	= PictureLib.SettingsStorage;
		
	Else		
		
		TreeItem.EnableAuditLog				= DataHistoryUseValueAsBoolean(MetadataObject.DataHistory);
		TreeItem.InfobaseSettingsPicture	= Undefined;
		
	EndIf;
	
	InitializeMetadataObjectsTreeItemForObjectFields(TreeItem, MetadataObject, DataHistorySettings);
			
EndProcedure // InitializeMetadataObjectsTreeItemForObject()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFields(TreeItem, MetadataObject, DataHistorySettings)
	
	Collection = MetadataObjectCollectionByMetadataObjectsTreeItem(TreeItem);
		
	FieldsItems = TreeItem.Fields.GetItems();
	FieldsItems.Clear();	
		
	ThereAreDimensions = 
		Collection.HasDimensions
		And MetadataObject.Dimensions.Count() > 0;
	
	If ThereAreDimensions Then
			
		InitializeMetadataObjectsTreeItemForObjectFieldsByDimensions(
			TreeItem, MetadataObject, DataHistorySettings, FieldsItems
		);		
		
	EndIf;	
	
	ThereAreResources = 
		Collection.HasResources
		And MetadataObject.Resources.Count() > 0;
	
	If ThereAreResources Then
			
		InitializeMetadataObjectsTreeItemForObjectFieldsByResources(
			TreeItem, MetadataObject, DataHistorySettings, FieldsItems
		);		
		
	EndIf;		
		
	ThereAreAttributes = 
		Collection.HasAttributes
		And
		(
			MetadataObject.Attributes.Count()				> 0 
			Or MetadataObject.StandardAttributes.Count()	> 0
		);
			
	If ThereAreAttributes Then
			
		InitializeMetadataObjectsTreeItemForObjectFieldsByAttributes(
			TreeItem, MetadataObject, DataHistorySettings, FieldsItems
		);		
		
	EndIf;	
	
	ThereAreTabularSections = 
		Collection.HasTabularSections
		And MetadataObject.TabularSections.Count() > 0;
	
	If ThereAreTabularSections Then		
			
		InitializeMetadataObjectsTreeItemForObjectFieldsByTabularSections(
			TreeItem, MetadataObject, DataHistorySettings, FieldsItems
		);
				
	EndIf;			
	
	InitializeMetadataObjectsTreeItemForObjectFieldsCollectionsUse(FieldsItems);
		
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFields()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFieldsCollectionsUse(FieldsItems)
	
	For Each FieldsItem In FieldsItems Do
		
		FieldItemItems = FieldsItem.GetItems();
		
		IsCollectionOfCollections = FieldItemItems[0].IsCollection;
		
		If IsCollectionOfCollections Then
			
			For Each FieldItemItem In FieldItemItems Do
				
				FieldItemItemSubItems = FieldItemItem.GetItems();
				
				UpdateTreeItemUseAccordingToSubItems(FieldItemItem, FieldItemItemSubItems);
				
			EndDo;
									
		EndIf;
		
		UpdateTreeItemUseAccordingToSubItems(FieldsItem, FieldItemItems);
		
	EndDo;	
	
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFieldsCollectionsUse()
	
&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFieldsByDimensions(TreeItem, MetadataObject, DataHistorySettings, FieldsItems)

	DimensionsBranch = FieldsItems.Add();
		
	DimensionsBranch.Presentation	= NStr("en = 'Dimensions'; ru = 'Измерения'");
	DimensionsBranch.Picture		= PictureLib.Dimension;
	DimensionsBranch.IsCollection	= True;
		
	DimensionsItems = DimensionsBranch.GetItems();
		
	For Each Dimension In MetadataObject.Dimensions Do
		
		InitializeMetadataObjectsTreeItemForObjectField(
			DataHistorySettings, DimensionsItems, PictureLib.Dimension, Dimension
		);
				
	EndDo;			
				
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFieldsByDimensions()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFieldsByResources(TreeItem, MetadataObject, DataHistorySettings, FieldsItems)

	ResourcesBranch = FieldsItems.Add();
		
	ResourcesBranch.Presentation	= NStr("en = 'Resources'; ru = 'Ресурсы'");
	ResourcesBranch.Picture			= PictureLib.Resource;
	ResourcesBranch.IsCollection	= True;
		
	ResourcesItems = ResourcesBranch.GetItems();
		
	For Each Resource In MetadataObject.Resources Do
		
		InitializeMetadataObjectsTreeItemForObjectField(
			DataHistorySettings, ResourcesItems, PictureLib.Resource, Resource
		);
				
	EndDo;			
				
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFieldsByResources()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFieldsByAttributes(TreeItem, MetadataObject, DataHistorySettings, FieldsItems)

	IsChartOfAccounts = Metadata.ChartsOfAccounts.Find(MetadataObject.Name) <> Undefined;
	
	AttributesBranch = FieldsItems.Add();
		
	AttributesBranch.Presentation	= NStr("en = 'Attributes'; ru = 'Реквизиты'");
	AttributesBranch.Picture		= PictureLib.Attribute;
	AttributesBranch.IsCollection	= True;
		
	AttributesItems = AttributesBranch.GetItems();
	
	For Each Attribute In MetadataObject.StandardAttributes Do

		If 
			IsChartOfAccounts 
			And IsStandardAttributeWithName(Attribute, MetadataObject, "Order") Then
			
			Continue;
			
		EndIf;
		
		InitializeMetadataObjectsTreeItemForObjectField(
			DataHistorySettings, AttributesItems, PictureLib.Attribute, Attribute
		);
				
	EndDo;				
	
	For Each Attribute In MetadataObject.Attributes Do
		
		InitializeMetadataObjectsTreeItemForObjectField(
			DataHistorySettings, AttributesItems, PictureLib.Attribute, Attribute
		);
				
	EndDo;			
				
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFieldsByAttributes()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectFieldsByTabularSections(TreeItem, MetadataObject, DataHistorySettings, FieldsItems)
	
	IsBusinessProcess = Metadata.BusinessProcesses.Find(MetadataObject.Name) <> Undefined;
	
	TabularSectionsBranch = FieldsItems.Add();
		
	TabularSectionsBranch.Presentation	= NStr("en = 'Tabular Sections'; ru = 'Табличные части'");
	TabularSectionsBranch.Picture		= PictureLib.NestedTable;
	TabularSectionsBranch.IsCollection	= True;
		
	TabularSectionsItems = TabularSectionsBranch.GetItems();		

	For Each TabularSection In MetadataObject.TabularSections Do
			
		TabularSectionBranch = TabularSectionsItems.Add();
			
		TabularSectionBranch.Presentation	= MetadataObjectPresentation(TabularSection);
		TabularSectionBranch.Picture		= PictureLib.NestedTable;
		TabularSectionBranch.IsCollection	= True;
		
		TabularSectionItems = TabularSectionBranch.GetItems();
		
		For Each Attribute In TabularSection.StandardAttributes Do
			
			If 
				IsBusinessProcess 
				And IsStandardAttributeWithName(Attribute, TabularSection, "LineNumber") Then
								
				Continue;
				
			EndIf;
			
			InitializeMetadataObjectsTreeItemForObjectField(
				DataHistorySettings, TabularSectionItems, PictureLib.Attribute, Attribute, TabularSection
			);
					
		EndDo;						
		
		For Each Attribute In TabularSection.Attributes Do
			
			InitializeMetadataObjectsTreeItemForObjectField(
				DataHistorySettings, TabularSectionItems, PictureLib.Attribute, Attribute, TabularSection
			);
			
		EndDo;
		
	EndDo;
			
EndProcedure // InitializeMetadataObjectsTreeItemForObjectFieldsByTabularSections()

&AtServer
Procedure InitializeMetadataObjectsTreeItemForObjectField(DataHistorySettings, FieldBranchItems, Picture, Attribute, TabularSection = Undefined)

	If TabularSection = Undefined Then
		FieldName = Attribute.Name;
	Else
		FieldName = StrTemplate("%1.%2", TabularSection.Name, Attribute.Name);
	EndIf;
	
	NewRow = FieldBranchItems.Add();
	
	IsOverrided = 			
		DataHistorySettings								<> Undefined
		And DataHistorySettings.FieldsUse				<> Undefined 
		And DataHistorySettings.FieldsUse[FieldName]	<> Undefined;	
	
	If IsOverrided Then
		NewRow.EnableAuditLog = DataHistorySettings.FieldsUse[FieldName];
	Else
		NewRow.EnableAuditLog = DataHistoryUseValueAsNumber(Attribute.DataHistory);
	EndIf;
			
	NewRow.Name			= FieldName;
	NewRow.Presentation = MetadataObjectPresentation(Attribute);
	NewRow.Picture		= Picture;

EndProcedure // InitializeMetadataObjectsTreeItemForObjectField()

&AtServer
Function MetadataObjectByMetadataObjectsTreeItem(TreeItem)
	
	ObjectInfo = MetadataObjectInfoByMetadataObjectsTreeItem(TreeItem);
	
	Return Metadata[ObjectInfo.ManagerName][ObjectInfo.Name];
	
EndFunction // MetadataObjectByMetadataObjectsTreeItem()

&AtClientAtServerNoContext
Function MetadataObjectInfoByMetadataObjectsTreeItem(TreeItem)
	
	If TreeItem.IsCollection Then
		
		Return Undefined;
		
	Else
		
		ParentTreeItem = TreeItem.GetParent();
			
		Return New Structure("ManagerName, Name", ParentTreeItem.Name, TreeItem.Name);
		
	EndIf;	
	
EndFunction // MetadataObjectInfoByMetadataObjectsTreeItem()

#EndRegion // MetadataObjectsTree

#Region LoadDataHistorySettings

&AtServer
Function MetadataObjectPresentation(MetadataObject, Postfix = Undefined)
	
	If ShowMetadataObjectNames Then
		
		Presentation = MetadataObject.Name;
		
	Else
		
		IsBlankSynonym	= IsBlankString(MetadataObject.Synonym);		
		Presentation	= ? (IsBlankSynonym, MetadataObject.Name, MetadataObject.Synonym);
		
	EndIf;
	
	If Postfix <> Undefined Then
		Presentation = StrTemplate("%1 (%2)", Presentation, Postfix);
	EndIf;
	
	Return Presentation;
	
EndFunction // MetadataObjectPresentation()

&AtServer
Function MetadataObjectsValueTable(Collection)
	
	ObjectsTable = New ValueTable;
		
	ObjectsTable.Columns.Add("Name");
	ObjectsTable.Columns.Add("Presentation");
		
	For Each MetadataObject In Metadata[Collection.Name] Do
			
		NewRow = ObjectsTable.Add();
	
		NewRow.Name			= MetadataObject.Name;
		NewRow.Presentation = MetadataObjectPresentation(MetadataObject);
	
	EndDo;
		
	ObjectsTable.Sort("Presentation");	
	
	Return ObjectsTable;
	
EndFunction // MetadataObjectsValueTable()

&AtServer
Procedure LoadSettingsAtServer()

	MetadataObjectsTree.GetItems().Clear();
		
	For Each Collection In MetadataObjectsCollections Do
		LoadSettingsForMetadataObjectsCollection(Collection.Value);
	EndDo;
	
EndProcedure // LoadSettingsAtServer()

&AtServer
Procedure LoadSettingsForMetadataObjectsCollection(Collection)
		
	ObjectsNumber = Metadata[Collection.Name].Count();
	
	If ObjectsNumber > 0 Then
	
		ParentTreeItem				= MetadataObjectsTreeItemForCollection(Collection);
		MetadataObjectsValueTable	= MetadataObjectsValueTable(Collection);
		
		For Each Row In MetadataObjectsValueTable Do
			
			MetadataObject = Metadata[Collection.Name][Row.Name];
			
			ObjectItem = MetadataObjectsTreeItemForObject(ParentTreeItem, Collection, MetadataObject);
									
		EndDo;
		
		InitializeMetadataObjectsTreeItemForCollection(ParentTreeItem);
		
	EndIf;
		
EndProcedure // LoadSettingsForMetadataObjectsCollection()

&AtServer
Function MetadataObjectsTreeItemForCollection(Collection)
	
	Branches	= MetadataObjectsTree.GetItems();	
	Branch		= Branches.Add();
	
	FillPropertyValues(Branch, Collection, "Name, Presentation, Picture");
		
	Branch.IsCollection = True;
	
	Return Branch;
	
EndFunction // MetadataObjectsTreeItemForCollection()

&AtServer
Function MetadataObjectRecordsNumber(FullName)
	
	QueryText =
	"SELECT
	|	COUNT(UNDEFINED) AS RecordsNumber
	|
	|FROM
	|	%1 AS Table";
	
	QueryText	= StrTemplate(QueryText, FullName);	
	Query		= New Query(QueryText);
	
	QueryResult	= Query.Execute();	
	Result		= 0;
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();		
		Selection.Next();
		
		Result = Selection.RecordsNumber;
		
	EndIf;
	
	Return Result;
	
EndFunction // MetadataObjectRecordsNumber()

&AtServer
Function MetadataObjectsTreeItemForObject(ParentTreeItem, Collection, MetadataObject)

	//--> BIT FBI-2420 VKostyanetsky 13.03.2020
	
	FullName = MetadataObject.FullName();
	
	If MetadataObjectsToIgnore.FindByValue(FullName) <> Undefined Then
		Return Undefined;
	EndIf;
	
	//<-- BIT FBI-2420 VKostyanetsky 13.03.2020
	
	Try
		
		DataHistorySettings = DataHistory.GetSettings(MetadataObject);
		
		If ShowMetadataObjectRecordsNumber Then
			RecordsNumber = MetadataObjectRecordsNumber(FullName);
		Else
			RecordsNumber = Undefined;
		EndIf;
		
	Except
		
		Message = BriefErrorDescription(ErrorInfo());
		MessageToUser(Message);
		
		Return Undefined;
		                                     	
	EndTry;	
	
	TreeItem = ParentTreeItem.GetItems().Add();	
	
	TreeItem.Name			= MetadataObject.Name;
	TreeItem.Presentation	= MetadataObjectPresentation(MetadataObject, RecordsNumber);
	TreeItem.Picture		= Collection.Picture;
		
	InitializeMetadataObjectsTreeItemForObject(TreeItem, MetadataObject, DataHistorySettings);
	
	Return TreeItem;
	
EndFunction // MetadataObjectsTreeItemForObject()

#EndRegion // LoadDataHistorySettings

#Region CheckboxStates

&AtClientAtServerNoContext
Procedure MakeCheckboxNotChecked(Value)
	
	States = CheckboxStates();	
	
	Value = States.NotChecked;
	
EndProcedure // MakeCheckboxNotChecked()

&AtClientAtServerNoContext
Function IsCheckboxPartiallyChecked(Value)
	
	States = CheckboxStates();	
	
	Return Value = States.PartiallyChecked;
	
EndFunction // IsCheckboxPartiallyChecked()

&AtClientAtServerNoContext
Function IsCheckboxNotChecked(Value)
	
	States = CheckboxStates();	
	
	Return Value = States.NotChecked;
	
EndFunction // IsCheckboxNotChecked()

&AtClientAtServerNoContext
Function IsCheckboxChecked(Value)
	
	States = CheckboxStates();	
	
	Return Value = States.Checked;
	
EndFunction // IsCheckboxChecked()

&AtClientAtServerNoContext
Function CheckboxStates()
	
	Return New Structure("NotChecked, Checked, PartiallyChecked", 0, 1, 2);
		
EndFunction // CheckboxStates()

#EndRegion // CheckboxStates

&AtServerNoContext
Function IsStandardAttributeWithName(Attribute, MetadataObject, StandardAttributeName)
	
	Try
		
		Result = 
			Attribute.Name = MetadataObject.StandardAttributes[StandardAttributeName].Name;
		
	Except
		
		Result = False;		
		
	EndTry;
	
	Return Result;
	
EndFunction // IsStandardAttributeWithName()

&AtClient
Procedure ChangeMetadataObjectFieldsUse(Branch, Value)
	
	ItemsToChange = Branch.GetItems();
	
	For Each ItemToChange In ItemsToChange Do
		
		ItemToChange.EnableAuditLog = Value;
		
		ChangeMetadataObjectFieldsUse(ItemToChange, Value);
		
	EndDo;
	
EndProcedure // ChangeMetadataObjectFieldsUse()

&AtClient
Procedure ChangeAuditLogState(Value)
	
	MessageText	= NStr(
		"en = 'Updating audit log settings...';
		|ru = 'Обновление настроек истории данных...'"
	);
		
	Status(MessageText);			
		
	TreeItemIDs = New Array;
	
	For Each ID In Items.MetadataObjectsTree.SelectedRows Do
		
		TreeItem = MetadataObjectsTree.FindByID(ID);
		
		If TreeItem.IsCollection Then
				
			SubTreeItems = TreeItem.GetItems();
				
			For Each SubTreeItem In SubTreeItems Do								
				
				SubTreeItem.EnableAuditLog = Value;
				TreeItemIDs.Add(SubTreeItem.GetID());
				
			EndDo;
								
		Else
			
			TreeItem.EnableAuditLog = Value;
			TreeItemIDs.Add(TreeItem.GetID());
								
		EndIf;			
		
	EndDo;
		
	SetSettingsForSelectedMetadataObjectAtServer(TreeItemIDs);
	
	MessageText	= NStr(
		"en = 'Updating audit log settings is completed.';
		|ru = 'Обновление настроек истории данных завершено.'"
	);
	
	Status(MessageText);	

EndProcedure // ChangeAuditLogState()

&AtServer
Function DataHistoryUseValueAsBoolean(Value)
	
	Return Value = Metadata.ObjectProperties.DataHistoryUse.Use;
	
EndFunction // DataHistoryUseValueAsBoolean()

&AtServer
Function DataHistoryUseValueAsNumber(Value)
	
	Return ? (Value = Metadata.ObjectProperties.DataHistoryUse.Use, 1, 0);
	
EndFunction // DataHistoryUseValueAsNumber()

&AtClientAtServerNoContext
Procedure MessageToUser(Text)

	Message = New UserMessage;
	Message.Text = Text;
	
	Message.Message();
	
EndProcedure // MessageToUser()

&AtClientAtServerNoContext
Procedure UpdateTreeItemUseAccordingToSubItems(TreeItem, TreeItemSubItems)
	
	ThereAreEnabledFieldsOnly	= True;
	ThereAreDisabledFieldsOnly	= True;
		
	For Each TreeItemSubItem In TreeItemSubItems Do
		
		If IsCheckboxNotChecked(TreeItemSubItem.EnableAuditLog) Then
			
			ThereAreEnabledFieldsOnly = False;
			
		ElsIf IsCheckboxChecked(TreeItemSubItem.EnableAuditLog) Then
			
			ThereAreDisabledFieldsOnly = False;
			
		Else // (checkbox is checked partially)
						
			ThereAreEnabledFieldsOnly	= False;
			ThereAreDisabledFieldsOnly	= False;
			
		EndIf;
		
	EndDo;	
	
	If ThereAreEnabledFieldsOnly Then
		TreeItem.EnableAuditLog = 1;
	ElsIf ThereAreDisabledFieldsOnly Then
		TreeItem.EnableAuditLog = 0;
	Else
		TreeItem.EnableAuditLog = 2;
	EndIf;	
		
EndProcedure // UpdateTreeItemUseAccordingToSubItems()

#EndRegion // Private