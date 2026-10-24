import Cocoa

/// Classic keyboard shortcuts like copy-and-paste are missing without a MainMenu
/// see https://stackoverflow.com/a/3746058/2249756
class MainMenu {
    private static var mainMenu: NSMenu!
    private static var menuItemsWithShortcut = [NSMenuItem: String]()
    private static var editMenuItems = Set<NSMenuItem>()
    private static var toggleState = true
    private static var editToggleState = true

    static func create() {
        mainMenu = NSMenu(title: "Главное меню")
        mainMenu.addItem(appMenuItem())
        mainMenu.addItem(fileMenuItem())
        mainMenu.addItem(editMenuItem())
        mainMenu.addItem(formatMenuItem())
        mainMenu.addItem(windowMenuItem())
        mainMenu.addItem(helpMenuItem())
        App.shared.mainMenu = mainMenu
        rememberMenuItemsWithShortcut()
    }

    static func toggle(_ enabled: Bool) {
        guard toggleState != enabled else { return }
        toggleState = enabled
        for (item, keyEquivalent) in menuItemsWithShortcut {
            item.keyEquivalent = enabled ? keyEquivalent : ""
        }
        // toggle() also touches Edit items; keep editToggleState in sync so a
        // following toggleEditMenu(true) doesn't no-op and leave them disabled.
        editToggleState = enabled
    }

    static func toggleEditMenu(_ enabled: Bool) {
        guard editToggleState != enabled else { return }
        editToggleState = enabled
        for item in editMenuItems {
            guard let keyEquivalent = menuItemsWithShortcut[item] else { continue }
            item.keyEquivalent = enabled ? keyEquivalent : ""
        }
    }

    private static func rememberMenuItemsWithShortcut() {
        guard let items = mainMenu?.items else { return }
        let editSubmenu = items.first { $0.submenu?.title == "Правка" }?.submenu
        var stack: [(NSMenu, Bool)] = [(mainMenu, false)]
        while let (menu, isEdit) = stack.popLast() {
            let isEditMenu = isEdit || menu === editSubmenu
            for item in menu.items {
                if !item.keyEquivalent.isEmpty {
                    menuItemsWithShortcut[item] = item.keyEquivalent
                    if isEditMenu { editMenuItems.insert(item) }
                }
                if let submenu = item.submenu {
                    stack.append((submenu, isEditMenu))
                }
            }
        }
    }

    // MARK: - Menu builders

    private static func appMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "AltTab")
        menu.addItem(item("Настройки…", "orderFrontPreferencesPanel:", ","))
        menu.addItem(.separator())
        let servicesItem = NSMenuItem(title: "Службы", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Службы")
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        menu.addItem(servicesItem)
        menu.addItem(.separator())
        menu.addItem(item("Показать все", "unhideAllApplications:"))
        menu.addItem(.separator())
        menu.addItem(item("Завершить AltTab", "terminate:", "q"))
        return menuBarItem(menu)
    }

    private static func fileMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Файл")
        menu.addItem(item("Закрыть", "performClose:", "w"))
        menu.addItem(.separator())
        menu.addItem(item("Параметры страницы…", "runPageLayout:", "P", [.shift, .command]))
        menu.addItem(item("Напечатать…", "print:", "p"))
        return menuBarItem(menu)
    }

    private static func editMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Правка")
        menu.addItem(item("Отменить", "undo:", "z"))
        menu.addItem(item("Повторить", "redo:", "Z", [.shift, .command]))
        menu.addItem(.separator())
        menu.addItem(item("Вырезать", "cut:", "x"))
        menu.addItem(item("Скопировать", "copy:", "c"))
        menu.addItem(item("Вставить", "paste:", "v"))
        menu.addItem(item("Вставить и согласовать стиль", "pasteAsPlainText:", "V", [.option, .shift, .command]))
        menu.addItem(item("Удалить", "delete:"))
        menu.addItem(item("Выбрать все", "selectAll:", "a"))
        menu.addItem(.separator())
        menu.addItem(submenuItem("Найти", findMenu()))
        menu.addItem(submenuItem("Правописание и грамматика", spellingMenu()))
        menu.addItem(submenuItem("Замены", substitutionsMenu()))
        menu.addItem(submenuItem("Преобразования", transformationsMenu()))
        menu.addItem(submenuItem("Речь", speechMenu()))
        return menuBarItem(menu)
    }

    private static func findMenu() -> NSMenu {
        let menu = NSMenu(title: "Найти")
        menu.addItem(taggedItem("Найти…", "performFindPanelAction:", "f", 1))
        menu.addItem(taggedItem("Найти и заменить…", "performFindPanelAction:", "f", 12, [.option, .command]))
        menu.addItem(taggedItem("Найти далее", "performFindPanelAction:", "g", 2))
        menu.addItem(taggedItem("Найти ранее", "performFindPanelAction:", "G", 3, [.shift, .command]))
        menu.addItem(taggedItem("Использовать выделенное для поиска", "performFindPanelAction:", "e", 7))
        menu.addItem(item("Перейти к выделенному", "centerSelectionInVisibleArea:", "j"))
        return menu
    }

    private static func spellingMenu() -> NSMenu {
        let menu = NSMenu(title: "Правописание")
        menu.addItem(item("Показать правописание и грамматику", "showGuessPanel:", ":"))
        menu.addItem(item("Проверить документ", "checkSpelling:", ";"))
        menu.addItem(.separator())
        menu.addItem(item("Проверять правописание при вводе", "toggleContinuousSpellChecking:"))
        menu.addItem(item("Проверять грамматику с правописанием", "toggleGrammarChecking:"))
        menu.addItem(item("Автоматически исправлять правописание", "toggleAutomaticSpellingCorrection:"))
        return menu
    }

    private static func substitutionsMenu() -> NSMenu {
        let menu = NSMenu(title: "Замены")
        menu.addItem(item("Показать замены", "orderFrontSubstitutionsPanel:"))
        menu.addItem(.separator())
        menu.addItem(item("Смарт-копирование/вставка", "toggleSmartInsertDelete:"))
        menu.addItem(item("Смарт-кавычки", "toggleAutomaticQuoteSubstitution:"))
        menu.addItem(item("Смарт-тире", "toggleAutomaticDashSubstitution:"))
        menu.addItem(item("Смарт-ссылки", "toggleAutomaticLinkDetection:"))
        menu.addItem(item("Детекторы данных", "toggleAutomaticDataDetection:"))
        menu.addItem(item("Замена текста", "toggleAutomaticTextReplacement:"))
        return menu
    }

    private static func transformationsMenu() -> NSMenu {
        let menu = NSMenu(title: "Преобразования")
        menu.addItem(item("Сделать прописными", "uppercaseWord:"))
        menu.addItem(item("Сделать строчными", "lowercaseWord:"))
        menu.addItem(item("Сделать заглавными первые буквы", "capitalizeWord:"))
        return menu
    }

    private static func speechMenu() -> NSMenu {
        let menu = NSMenu(title: "Речь")
        menu.addItem(item("Начать речь", "startSpeaking:"))
        menu.addItem(item("Остановить речь", "stopSpeaking:"))
        return menu
    }

    private static func formatMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Формат")
        menu.addItem(submenuItem("Шрифт", fontMenu()))
        menu.addItem(submenuItem("Текст", textMenu()))
        return menuBarItem(menu)
    }

    private static func fontMenu() -> NSMenu {
        let fontManager = NSFontManager.shared
        let menu = NSMenu(title: "Шрифт")
        menu.addItem(item("Показать шрифты", "orderFrontFontPanel:", "t", target: fontManager))
        menu.addItem(taggedItem("Жирный", "addFontTrait:", "b", 2, target: fontManager))
        menu.addItem(taggedItem("Курсив", "addFontTrait:", "i", 1, target: fontManager))
        menu.addItem(item("Подчеркнутый", "underline:", "u"))
        menu.addItem(.separator())
        menu.addItem(taggedItem("Больше", "modifyFont:", "+", 3, target: fontManager))
        menu.addItem(taggedItem("Меньше", "modifyFont:", "-", 4, target: fontManager))
        menu.addItem(.separator())
        menu.addItem(submenuItem("Кернинг", kernMenu()))
        menu.addItem(submenuItem("Лигатуры", ligaturesMenu()))
        menu.addItem(submenuItem("Базовая линия", baselineMenu()))
        menu.addItem(.separator())
        menu.addItem(item("Показать цвета", "orderFrontColorPanel:", "C", [.shift, .command]))
        menu.addItem(.separator())
        menu.addItem(item("Скопировать стиль", "copyFont:", "c", [.option, .command]))
        menu.addItem(item("Вставить стиль", "pasteFont:", "v", [.option, .command]))
        return menu
    }

    private static func kernMenu() -> NSMenu {
        let menu = NSMenu(title: "Кернинг")
        menu.addItem(item("По умолчанию", "useStandardKerning:"))
        menu.addItem(item("Не использовать", "turnOffKerning:"))
        menu.addItem(item("Сжать", "tightenKerning:"))
        menu.addItem(item("Разрядить", "loosenKerning:"))
        return menu
    }

    private static func ligaturesMenu() -> NSMenu {
        let menu = NSMenu(title: "Лигатуры")
        menu.addItem(item("По умолчанию", "useStandardLigatures:"))
        menu.addItem(item("Не использовать", "turnOffLigatures:"))
        menu.addItem(item("Использовать все", "useAllLigatures:"))
        return menu
    }

    private static func baselineMenu() -> NSMenu {
        let menu = NSMenu(title: "Базовая линия")
        menu.addItem(item("По умолчанию", "unscript:"))
        menu.addItem(item("Надстрочный", "superscript:"))
        menu.addItem(item("Подстрочный", "subscript:"))
        menu.addItem(item("Поднять", "raiseBaseline:"))
        menu.addItem(item("Опустить", "lowerBaseline:"))
        return menu
    }

    private static func textMenu() -> NSMenu {
        let menu = NSMenu(title: "Текст")
        menu.addItem(item("По левому краю", "alignLeft:", "{"))
        menu.addItem(item("По центру", "alignCenter:", "|"))
        menu.addItem(item("По ширине", "alignJustified:"))
        menu.addItem(item("По правому краю", "alignRight:", "}"))
        menu.addItem(.separator())
        menu.addItem(submenuItem("Направление письма", writingDirectionMenu()))
        menu.addItem(.separator())
        menu.addItem(item("Показать линейку", "toggleRuler:"))
        menu.addItem(item("Скопировать линейку", "copyRuler:", "c", [.control, .command]))
        menu.addItem(item("Вставить линейку", "pasteRuler:", "v", [.control, .command]))
        return menu
    }

    private static func writingDirectionMenu() -> NSMenu {
        let menu = NSMenu(title: "Направление письма")
        let paragraph = NSMenuItem(title: "Абзац", action: nil, keyEquivalent: "")
        paragraph.isEnabled = false
        menu.addItem(paragraph)
        menu.addItem(item("\tПо умолчанию", "makeBaseWritingDirectionNatural:"))
        menu.addItem(item("\tСлева направо", "makeBaseWritingDirectionLeftToRight:"))
        menu.addItem(item("\tСправа налево", "makeBaseWritingDirectionRightToLeft:"))
        menu.addItem(.separator())
        let selection = NSMenuItem(title: "Выделенный текст", action: nil, keyEquivalent: "")
        selection.isEnabled = false
        menu.addItem(selection)
        menu.addItem(item("\tПо умолчанию", "makeTextWritingDirectionNatural:"))
        menu.addItem(item("\tСлева направо", "makeTextWritingDirectionLeftToRight:"))
        menu.addItem(item("\tСправа налево", "makeTextWritingDirectionRightToLeft:"))
        return menu
    }

    private static func windowMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Окно")
        menu.addItem(item("Свернуть", "performMiniaturize:", "m"))
        menu.addItem(item("Изменить масштаб", "performZoom:"))
        menu.addItem(.separator())
        menu.addItem(item("Все окна — на передний план", "arrangeInFront:"))
        NSApp.windowsMenu = menu
        return menuBarItem(menu)
    }

    private static func helpMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Справка")
        menu.addItem(item("Справка AltTab", "showHelp:", "?"))
        NSApp.helpMenu = menu
        return menuBarItem(menu)
    }

    // MARK: - Helpers

    private static func menuBarItem(_ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func submenuItem(_ title: String, _ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func item(_ title: String, _ action: String, _ key: String = "", _ modifiers: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: Selector(action), keyEquivalent: key)
        item.keyEquivalentModifierMask = key.isEmpty ? [] : modifiers
        item.target = target
        return item
    }

    private static func taggedItem(_ title: String, _ action: String, _ key: String, _ tag: Int, _ modifiers: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) -> NSMenuItem {
        let item = self.item(title, action, key, modifiers, target: target)
        item.tag = tag
        return item
    }
}
