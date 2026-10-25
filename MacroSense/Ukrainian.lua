-- Ukrainian: the translations of MacroSense's texts, by their English text (Locale.lua). A text missing here
-- shows in English. Each keeps the %s and %d of its English text, in the same order; macro syntax (/cast,
-- [mod:shift], #showtooltip), key names and the game's own names stay as they are. A list is the three forms of
-- a count (ns.Plural): for 1, for 2-4 and for 5 or more.
local _, ns = ...
ns = ns or {}
ns.locales = ns.locales or {}

ns.locales.uk = {
    -- Chat, /ms
    ["%s - thanks for trying it! The addon is in early development."] =
        "%s — дякую, що спробували! Аддон на ранньому етапі розробки.",
    ["  Found a bug or have an idea? Please don't hesitate to tell me: I read every report"] =
        "  Знайшли помилку чи маєте ідею? Не соромтеся написати мені: я читаю кожне повідомлення",
    ["  and try to fix things as fast as I can. Type /ms bug for the details to include."] =
        "  і намагаюся все виправляти якнайшвидше. Наберіть /ms bug, щоб отримати подробиці для звіту.",
    ["  Report here: %s"] = "  Пишіть сюди: %s",
    ["on"] = "увімк.",
    ["off"] = "вимк.",
    ["autocomplete %s"] = "автодоповнення: %s",
    ["minimap button %s"] = "кнопка біля мінікарти: %s",
    ["bug report details:"] = "подробиці для звіту про помилку:",
    ["  Please describe what you did, what you expected and what happened; a screenshot helps."] =
        "  Опишіть, що ви робили, чого очікували і що сталося; знімок екрана теж допоможе.",
    ["debug %s"] = "налагодження: %s",
    ["/ms - open the editor; /ms minimap - hide or show the minimap button; /ms bug - details for a bug report; "
        .. "/ms autocomplete | debug - toggle"] =
        "/ms — відкрити редактор; /ms minimap — сховати чи показати кнопку біля мінікарти; /ms bug — подробиці "
        .. "для звіту про помилку; /ms autocomplete | debug — увімкнути чи вимкнути",

    -- Main window: header
    ["English"] = "Англійська",
    ["Ukrainian"] = "Українська",
    ["Language"] = "Мова",
    ["The language of MacroSense. The interface reloads to switch it."] =
        "Мова MacroSense. Щоб змінити її, інтерфейс перезавантажиться.",
    ["Reload the interface to switch the language?"] = "Перезавантажити інтерфейс, щоб змінити мову?",
    ["Reload"] = "Перезавантажити",
    ["Later"] = "Пізніше",
    ["Dark"] = "Темна",
    ["Light"] = "Світла",
    ["Graphite"] = "Графіт",
    ["Charcoal"] = "Вугілля",
    ["Paper"] = "Папір",
    ["Solarized Dark"] = "Solarized темна",
    ["Live preview"] = "Живий перегляд",
    ["Next to each line: what it would do if you pressed the macro now."] =
        "Біля кожного рядка: що він зробив би, якби ви натиснули макрос зараз.",
    ["Hold %s, change your target or point at a unit to see the other branches."] =
        "Утримуйте %s, змініть ціль або наведіть мишку на когось, щоб побачити інші гілки.",
    ["Shift, Ctrl, Alt or Cmd"] = "Shift, Ctrl, Alt чи Cmd",
    ["Shift, Ctrl or Alt"] = "Shift, Ctrl чи Alt",

    -- Main window: list
    ["General"] = "Загальні",
    ["Character"] = "Персонаж",
    ["General  %d/%d"] = "Загальні  %d/%d",
    ["Character  %d/%d"] = "Персонаж  %d/%d",
    ["General  (%d)"] = "Загальні  (%d)",
    ["Character  (%d)"] = "Персонаж  (%d)",
    ["Search name or text"] = "Пошук за назвою чи текстом",
    ["No macros match"] = "Нічого не знайдено",
    ["Delete this macro"] = "Видалити цей макрос",
    ["Copy this macro"] = "Копіювати цей макрос",
    ["Duplicate"] = "Дублювати",
    ["Copy to Character"] = "Копіювати в «Персонаж»",
    ["Copy to General"] = "Копіювати в «Загальні»",
    ["(full)"] = "(заповнена)",
    ["The %s tab is full."] = "Вкладка «%s» заповнена.",
    ["A copy in this tab with what the editor shows now, under a free name like \"Fear 2\". The macro copied keeps "
        .. "its saved text."] =
        "Копія в цій вкладці з тим, що зараз у редакторі, під вільною назвою на кшталт «Fear 2». Сам макрос "
        .. "лишається таким, як збережений.",
    ["A copy for this character only with what the editor shows now, under a free name like \"Fear 2\". The macro "
        .. "copied keeps its saved text."] =
        "Копія лише для цього персонажа з тим, що зараз у редакторі, під вільною назвою на кшталт «Fear 2». Сам "
        .. "макрос лишається таким, як збережений.",
    ["A copy for all your characters with what the editor shows now, under a free name like \"Fear 2\". The macro "
        .. "copied keeps its saved text."] =
        "Копія для всіх ваших персонажів з тим, що зараз у редакторі, під вільною назвою на кшталт «Fear 2». Сам "
        .. "макрос лишається таким, як збережений.",
    ["A copy in this tab, under a free name like \"Fear 2\"."] =
        "Копія в цій вкладці під вільною назвою на кшталт «Fear 2».",
    ["A copy for this character only, under a free name like \"Fear 2\"."] =
        "Копія лише для цього персонажа під вільною назвою на кшталт «Fear 2».",
    ["A copy for all your characters, under a free name like \"Fear 2\"."] =
        "Копія для всіх ваших персонажів під вільною назвою на кшталт «Fear 2».",
    ["New"] = "Новий",
    ["New (Wizard)"] = "Майстер",
    ["A new macro from a form: what to cast and on whom (mouseover, focus, party members, yourself, the cursor...), "
        .. "other spells on Shift, Ctrl or Alt, trinkets and more."] =
        "Новий макрос через форму: що застосувати й на кого (mouseover, фокус, члени групи, ви самі, курсор...), "
        .. "інші заклинання на Shift, Ctrl чи Alt, аксесуари та інше.",

    -- Main window: share, trash, backups
    ["Share"] = "Обмін",
    ["Macros as a code to copy and send, and codes from others to import."] =
        "Макроси як код, щоб скопіювати й надіслати, і коди від інших, щоб імпортувати.",
    ["Export this macro"] = "Експортувати цей макрос",
    ["Its code, as saved, to copy and share."] = "Його код (як збережений), щоб скопіювати й поділитися.",
    ["Save the macro first, then export it."] = "Спершу збережіть макрос, потім експортуйте його.",
    ["Export the %s tab (%d)"] = "Експортувати вкладку «%s» (%d)",
    ["The code of every macro in this tab."] = "Код усіх макросів цієї вкладки.",
    ["Export all macros (%d)"] = "Експортувати всі макроси (%d)",
    ["The code of every macro of both tabs; imported, each goes into its own tab."] =
        "Код усіх макросів обох вкладок; під час імпорту кожен потрапить у свою вкладку.",
    ["Import a code..."] = "Імпортувати код...",
    ["Paste a code to make its macros. Nothing is replaced: a taken name gets a number, like \"Fear 2\"."] =
        "Вставте код, щоб створити його макроси. Нічого не замінюється: зайнята назва отримує номер, як «Fear 2».",
    ["imported %d of %d macros"] = "імпортовано макросів: %d з %d",
    ["Trash"] = "Кошик",
    ["Macros deleted here, in the game's macro window or by another addon: pick one to bring it back."] =
        "Макроси, видалені тут, у стандартному вікні макросів чи іншим аддоном: оберіть, щоб повернути.",
    ["Deleted from %s: %s. Click to bring it back."] = "Видалено з вкладки «%s»: %s. Клацніть, щоб повернути.",
    ["Delete for good"] = "Видалити назавжди",
    ["No deleted macros"] = "Видалених макросів немає",
    ["%d older"] = { "ще %d старіший", "ще %d старіші", "ще %d старіших" },
    ["Empty the trash"] = "Очистити кошик",
    ["Empty the trash? Its %s deleted macros will be gone for good."] =
        "Очистити кошик? Видалені макроси (%s) зникнуть назавжди.",
    ["Delete \"%s\" from the trash? It will be gone for good."] = "Видалити «%s» з кошика? Він зникне назавжди.",
    ["could not restore the macro"] = "не вдалося повернути макрос",
    ["Backups"] = "Копії",
    ["All your macros as they were: one is made each day you log in and they changed, and whenever you ask. Pick "
        .. "one to restore it."] =
        "Усі ваші макроси такими, якими вони були: копія робиться щодня, коли ви входите в гру, якщо макроси "
        .. "змінилися, і будь-коли на ваше прохання. Оберіть копію, щоб відновити її.",
    ["Back up now"] = "Зробити копію зараз",
    ["A backup of all your macros, General and Character. One is also made by itself on the first login of a day "
        .. "when they changed; the last %d backups are kept for each character."] =
        "Копія всіх ваших макросів, загальних і персонажа. Вона також робиться сама при першому вході за день, "
        .. "якщо макроси змінилися; для кожного персонажа зберігаються останні %d копій.",
    ["%d macros"] = { "%d макрос", "%d макроси", "%d макросів" },
    ["Backup of %s"] = "Копія: %s",
    ["General %d, Character %d. Click to restore it."] = "Загальних: %d, персонажа: %d. Клацніть, щоб відновити.",
    [" and %d more"] = " і ще %d",
    ["Delete this backup"] = "Видалити цю копію",
    ["No backups yet"] = "Копій ще немає",
    ["no macros to back up"] = "немає макросів для копії",
    ["backed up %d macros"] = { "збережено копію: %d макрос", "збережено копію: %d макроси",
        "збережено копію: %d макросів" },
    ["your macros are as in the last backup"] = "ваші макроси такі самі, як в останній копії",
    ["backup restored: %d changed back, %d made again"] = "копію відновлено: повернуто — %d, створено знову — %d",
    ["%d did not fit: no free slot in their tab"] = { "%d не вмістився: у його вкладці немає вільного місця",
        "%d не вмістилися: у їхніх вкладках немає вільного місця",
        "%d не вмістилися: у їхніх вкладках немає вільного місця" },
    ["Restore the backup of %s?\n\nIts macros get their text and icon back and the missing ones are made again; "
        .. "macros made since stay. A backup of your macros now is made first."] =
        "Відновити копію (%s)?\n\nЇї макроси отримають назад свій текст та іконку, а відсутні буде створено "
        .. "знову; макроси, створені пізніше, лишаться. Спершу буде зроблено копію ваших макросів, якими вони є "
        .. "зараз.",
    ["Delete the backup of %s? It will be gone for good."] = "Видалити копію (%s)? Вона зникне назавжди.",

    -- Main window: editor
    ["Click: choose an icon"] = "Клацання: вибрати іконку",
    ["Drag: put the macro on an action bar"] = "Перетягування: поставити макрос на панель дій",
    ["click or drag the icon"] = "клацніть або перетягніть іконку",
    ["Shorten"] = "Скоротити",
    ["Shorten -%d"] = "Скоротити -%d",
    ["The same macro in fewer characters: target= becomes @, modifier becomes mod, [pet:Imp][pet:Felhunter] "
        .. "becomes [pet:Imp/Felhunter], [x] Fear; Fear becomes [x][]Fear, and spaces the game doesn't need go."] =
        "Той самий макрос меншою кількістю символів: target= стає @, modifier стає mod, [pet:Imp][pet:Felhunter] "
        .. "стає [pet:Imp/Felhunter], [x] Fear; Fear стає [x][]Fear, а зайві для гри пробіли зникають.",
    ["%s brings the old text back."] = "%s повертає попередній текст.",
    ["Nothing to shorten here."] = "Тут нічого скорочувати.",
    ["History"] = "Історія",
    ["Earlier saved versions of this macro. Pick one to put it in the editor: Save keeps it, %s takes it back."] =
        "Попередні збережені версії цього макросу. Оберіть версію, щоб поставити її в редактор: «Зберегти» "
        .. "залишить її, %s поверне назад.",
    ["When you save a change to this macro, here or in the game's macro window, the text it had before is kept "
        .. "here."] =
        "Коли ви зберігаєте зміну цього макросу, тут чи в стандартному вікні макросів, текст, який був до неї, "
        .. "зберігається тут.",
    ["%d chars"] = { "%d символ", "%d символи", "%d символів" },
    ["Today, %s"] = "Сьогодні, %s",
    ["Yesterday, %s"] = "Учора, %s",
    ["{month} {day}"] = "{day} {month}",
    ["Jan"] = "січ.",
    ["Feb"] = "лют.",
    ["Mar"] = "бер.",
    ["Apr"] = "квіт.",
    ["May"] = "трав.",
    ["Jun"] = "черв.",
    ["Jul"] = "лип.",
    ["Aug"] = "серп.",
    ["Sep"] = "вер.",
    ["Oct"] = "жовт.",
    ["Nov"] = "лист.",
    ["Dec"] = "груд.",
    ["Save"] = "Зберегти",
    ["Revert"] = "Відкотити",
    ["The macro has syntax errors"] = "У макросі є синтаксичні помилки",
    ["It can still be saved."] = "Його все одно можна зберегти.",
    ["Unsaved changes"] = "Незбережені зміни",
    ["Macro is longer than %d characters"] = "Макрос довший за %d символів",
    ["Ln %d, Col %d"] = "Рядок %d, стовпець %d",
    ["Line %d: %s"] = "Рядок %d: %s",
    [" (+%d more)"] = " (+ще %d)",
    ["Click to use \"%s\""] = "Клацніть, щоб вставити «%s»",
    ["Discard unsaved changes to this macro?"] = "Відкинути незбережені зміни цього макросу?",
    ["Delete macro \"%s\"?"] = "Видалити макрос «%s»?",
    ["Yes"] = "Так",
    ["No"] = "Ні",
    ["Delete"] = "Видалити",
    ["Cancel"] = "Скасувати",
    ["macros cannot be changed in combat"] = "у бою макроси змінювати не можна",
    ["action bars cannot be changed in combat"] = "у бою панелі дій змінювати не можна",
    ["the macro needs a name"] = "макросу потрібна назва",
    ["macro is longer than %d characters"] = "макрос довший за %d символів",
    ["could not save the macro"] = "не вдалося зберегти макрос",
    ["could not copy the macro"] = "не вдалося скопіювати макрос",
    ["save the macro first, then drag it to an action bar"] =
        "спершу збережіть макрос, а потім перетягніть його на панель дій",
    ["no free general macro slots"] = "немає вільних місць для загальних макросів",
    ["no free character macro slots"] = "немає вільних місць для макросів персонажа",
}
