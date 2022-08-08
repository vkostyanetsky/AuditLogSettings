# Audit Log Settings

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Read this page in Russian](README-ru.md)

It is a data processor intended to customize data history mechanism of the 1C:Enterprise platform. Written for the 8.3.16 version; supports exchange plans, constants, catalogs, documents, charts of characteristic types, charts of accounts, charts of compensation types, information registers, business processes and tasks.

![Data History Settings (FirstBIT ERP)](Images/DataHistorySettings.png "Data History Settings (FirstBIT ERP)")

There is an interface in English and Russian. The code is in English. Logic is not based on BSP or SSLi (that means it will work in any self-written configuration without additional adaptation).

## How to use

On the left side is the metadata tree. Only those metadata objects for which the platform can keep a history are displayed.

The data processor reads the settings from the metadata firstly, then from the infobase. Then it determines which objects do not have data history and marks gray.

When an object is selected, the settings for it are displayed in the panel on the right side. There you can enable or disable the history for the entire object, as well as for each attribute separately, if the object has them (for example, constants do not).

Available commands:

- `Refresh Settings` builds a tree of metadata objects and defines their settings. This operation is performed each time the data processor starts. It can take a decent amount of time (the more objects in the configuration, the more time it takes).
- `Enable Audit Log` and `Disable Audit Log` work for selected objects, considering their hierarchy. For example, you can enable history for all objects in the Catalogs and Documents branches by selecting them and clicking `Enable Data History`.
- `Set Default Metadata Settings` removes the settings of the data history mechanism from the infobase. Thereafter, the standard configuration settings defined by its developers will start working. Like on-off, this command works for selected objects.

## Hidden Features

There are hidden elements on the data processor form that I found not particularly useful for an ordinary user. You can enable them with the standard `Change form` command.

- `Infobase Settings Picture`. A column of the tree of metadata objects. It will display a gear for those objects that have at least some data history settings in the infobase. It is convenient if you need to understand for which objects the behavior of the data history differs from what the developer has set by default.
- `Show Metadata Object Names`. A checkbox in the footer of the form. If enabled, names will be displayed instead of object synonyms (and their attributes). It is convenient if you have a mess of synonyms, and it is hard to understand which history you turn on or off.
- `Show Metadata Object Records`. A checkbox in the footer of the form. If enabled, the number of records will be displayed for each metadata object. Useful, if you need to quickly estimate the overhead of maintaining data history.

## Possible problems

### Lack of rights

The data processor assumes that a user has the "Update data history settings" right for all configuration objects that it supports. If this is not true, it will fail.

### Old platform version

If you have an outdated version of the platform, remove the definition of objects that your platform does not support from the DefineMetadataObjectsCollections() procedure.

For example, for 8.3.12, you need to remove the definition of exchange plans and constants. If this is not done, the data processor will throw errors every time it starts.

### Service objects available

By default, the data processor displays all objects for which history can be kept. However, there is no point in versioning many of them: for example, BSP's `MetadataObjectIdentifiers`, a huge stack of registers for RLS and other service tables. If you want to avoid stuffing your database with garbage, it is better not to give users the opportunity to enable history for such tables. In addition, if your configuration can work in service mode, then hiding all unshared objects from the interface of the data processor is an excellent idea.

You can hide some objects by adding them to the MetadataObjectsToIgnore form attribute. This is a list of values. It can be filled, for example, when creating a form:

```
MetadataObjectsToIgnore.Add(Metadata.InformationRegisters.AccessGroupTables.FullName());
MetadataObjectsToIgnore.Add(Metadata.InformationRegisters.AccessGroupValues.FullName());
```

### Standard requisites are not supported

Currently, you cannot enable data history for:

1. Details "Order" of any chart of accounts;
2. The "Line Number" attribute of the tabular part of any business process.

Why? Have no clue. There is no single word about this in the documentation, and the platform just indifferently throws an exception. Most likely, its developers will fix this soon.

So far, I have disabled working with these details in the code, so the data processor ignores them and does not display them in the details tree. If you need to override this behavior, remove the If / EndIf blocks with code that calls the IsStandardAttributeWithName() function.
