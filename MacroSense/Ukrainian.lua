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
    ["|cff00ff00on|r"] = "|cff00ff00увімк.|r",
    ["|cffff0000off|r"] = "|cffff0000вимк.|r",
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
    ["See exactly how the macro will act: next to each line, what it would do if you pressed the macro now."] =
        "Тут видно, як саме діятиме макрос: біля кожного рядка — що він зробить, якщо натиснути макрос зараз.",
    ["Hold modifiers (%s), point the mouse at someone, change your target: use everything the macro checks to see "
        .. "which ability it uses, and when."] =
        "Затискайте модифікатори (%s), наводьте мишку, міняйте ціль — використовуйте все, що є в макросі, щоб "
        .. "побачити, яка саме здібність спрацює і в якій ситуації.",
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
    ["Create a new macro with the built-in wizard! Answer a few simple questions, or fill in the whole form at "
        .. "once: what to cast and on whom (mouseover, focus, party members, yourself, the cursor...), other spells on "
        .. "Shift, Ctrl or Alt, trinkets and more."] =
        "Створіть новий макрос за допомогою вбудованого майстра! Дайте відповідь на кілька простих питань або "
        .. "заповніть одразу всю форму: що застосувати й на кого (маусовер, фокус, члени групи, ви самі, курсор...), "
        .. "інші заклинання на Shift, Ctrl чи Alt, аксесуари та інше.",

    -- Main window: share, trash, backups
    ["Share"] = "Обмін",
    ["Share your macros with other players: just pass them the code made for them. Or add someone else's macros "
        .. "to yours, if you have their code."] =
        "Діліться своїми макросами з іншими гравцями: просто передайте їм згенерований код. Або додайте собі "
        .. "чужі макроси, якщо маєте їхній код.",
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
    ["Macros deleted by this addon, by any other or in the game's macro window land here, and you can bring them "
        .. "back. The trash keeps the last %d deleted macros of each tab; older ones are deleted by themselves. The "
        .. "menu shows the %d newest."] =
        "Макроси, видалені цим аддоном, будь-яким іншим чи стандартним вікном макросів, потрапляють сюди, і ви "
        .. "можете їх відновити. Кошик тримає останні %d видалених макросів кожної вкладки, старіші видаляються "
        .. "самі. У меню видно %d найновіших.",
    ["Deleted from %s: %s. Click to bring it back."] = "Видалено з вкладки «%s»: %s. Клацніть, щоб повернути.",
    ["Delete for good"] = "Видалити назавжди",
    ["No deleted macros"] = "Видалених макросів немає",
    ["%d older"] = { "ще %d старіший", "ще %d старіші", "ще %d старіших" },
    ["Empty the trash"] = "Очистити кошик",
    ["Empty the trash? Its %s deleted macros will be gone for good."] =
        "Очистити кошик? Видалені макроси (%s) зникнуть назавжди.",
    ["Delete \"%s\" from the trash? It will be gone for good."] = "Видалити «%s» з кошика? Він зникне назавжди.",
    ["could not restore the macro"] = "не вдалося повернути макрос",
    ["Backups"] = "Бекапи",
    ["Your macros are saved by themselves the first time you log in each day, if they changed since. You can also "
        .. "make a backup yourself, any time. To get your macros back as they were, just pick a backup. Each "
        .. "character keeps its last %d backups; older ones are deleted by themselves."] =
        "Ваші макроси зберігаються самі щодня, коли ви вперше заходите в гру, якщо з минулого разу вони "
        .. "змінилися. Бекап можна зробити й самому, будь-коли. Щоб повернути макроси такими, якими вони були, "
        .. "просто оберіть бекап. Для кожного персонажа лишаються останні %d бекапів, старіші видаляються самі.",
    ["Back up now"] = "Зробити бекап зараз",
    ["Saves all your macros now, General and this character's. Each character keeps its last %d backups; older "
        .. "ones are deleted by themselves."] =
        "Зберігає всі ваші макроси просто зараз, загальні й цього персонажа. Для кожного персонажа лишаються "
        .. "останні %d бекапів, старіші видаляються самі.",
    ["%d macros"] = { "%d макрос", "%d макроси", "%d макросів" },
    ["Backup of %s"] = "Бекап: %s",
    ["General %d, Character %d. Click to restore it."] = "Загальних: %d, персонажа: %d. Клацніть, щоб відновити.",
    [" and %d more"] = " і ще %d",
    ["Delete this backup"] = "Видалити цей бекап",
    ["No backups yet"] = "Бекапів ще немає",
    ["no macros to back up"] = "немає макросів для бекапу",
    ["backed up %d macros"] = { "зроблено бекап: %d макрос", "зроблено бекап: %d макроси",
        "зроблено бекап: %d макросів" },
    ["your macros are as in the last backup"] = "ваші макроси такі самі, як в останньому бекапі",
    ["backup restored: %d changed back, %d made again"] = "бекап відновлено: повернуто — %d, створено знову — %d",
    ["%d did not fit: no free slot in their tab"] = { "%d не вмістився: у його вкладці немає вільного місця",
        "%d не вмістилися: у їхніх вкладках немає вільного місця",
        "%d не вмістилися: у їхніх вкладках немає вільного місця" },
    ["Restore the backup of %s?\n\nIts macros get their text and icon back and the missing ones are made again; "
        .. "macros made since stay. A backup of your macros now is made first."] =
        "Відновити бекап (%s)?\n\nЙого макроси отримають назад свій текст та іконку, а відсутні буде створено "
        .. "знову; макроси, створені пізніше, лишаться. Спершу буде зроблено бекап ваших макросів, якими вони є "
        .. "зараз.",
    ["Delete the backup of %s? It will be gone for good."] = "Видалити бекап (%s)? Він зникне назавжди.",

    -- Main window: editor
    ["Click: choose an icon"] = "Клацання: вибрати іконку",
    ["Drag: put the macro on an action bar"] = "Перетягування: поставити макрос на панель дій",
    ["Its icon is the question mark: the macro shows the icon of the spell or item it uses."] =
        "Його іконка — знак питання: макрос показує іконку заклинання чи предмета, яке він застосовує.",
    ["click or drag the icon"] = "клацніть або перетягніть іконку",
    ["Shorten"] = "Скоротити",
    ["Shorten -%d"] = "Скоротити -%d",
    ["Tries to remove spaces the game doesn't need, shorten constructs and make the macro shorter overall, keeping "
        .. "everything it does. For example: target= becomes @, modifier becomes mod, [pet:Imp][pet:Felhunter] "
        .. "becomes [pet:Imp/Felhunter], [x] Fear; Fear becomes [x][]Fear."] =
        "Спробує прибрати зайві пробіли, скоротити конструкції й загалом зробити макрос коротшим, зберігши всю "
        .. "його функціональність. Наприклад: target= стає @, modifier стає mod, [pet:Imp][pet:Felhunter] стає "
        .. "[pet:Imp/Felhunter], [x] Fear; Fear стає [x][]Fear.",
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
    -- Share window
    ["Export a macro"] = "Експортувати макрос",
    ["Export %d macros"] = { "Експортувати %d макрос", "Експортувати %d макроси", "Експортувати %d макросів" },
    ["Press %s to copy the code, then share it: anyone with MacroSense can import it."] =
        "Натисніть %s, щоб скопіювати код, і поділіться ним: будь-хто з MacroSense зможе його імпортувати.",
    ["Import macros"] = "Імпортувати макроси",
    ["Paste a MacroSense code (%s). Nothing is replaced: a taken name gets a number."] =
        "Вставте код MacroSense (%s). Нічого не замінюється: зайнята назва отримує номер.",
    ["%d macros in the code:"] = { "У коді %d макрос:", "У коді %d макроси:", "У коді %d макросів:" },
    ["%s: into %s"] = "%s: у «%s»",
    ["%s: into %s as \"%s\" (the name is taken)"] = "%s: у «%s» як «%s» (назву вже зайнято)",
    ["%s: longer than the game allows, not imported"] = "%s: довший, ніж дозволяє гра, не імпортовано",
    ["%s: no free slot in %s"] = "%s: у «%s» немає вільного місця",
    ["... and %d more"] = "... і ще %d",
    ["Import"] = "Імпортувати",
    ["Close"] = "Закрити",
    ["This is not a MacroSense code."] = "Це не код MacroSense.",
    ["The code is cut short or changed: copy all of it again."] =
        "Код обрізаний або змінений: скопіюйте його ще раз повністю.",
    ["The code is damaged."] = "Код пошкоджений.",

    -- Wizard window
    ["New macro (Wizard)"] = "Новий макрос (майстер)",
    ["Command"] = "Команда",
    ["Name"] = "Назва",
    ["Tab"] = "Вкладка",
    ["Cast"] = "Заклинання",
    ["Use"] = "Предмет",
    ["type a spell or item"] = "заклинання чи предмет",
    ["spell or item"] = "заклинання чи предмет",
    ["spell"] = "заклинання",
    ["Pick a spell or item to cast, and the macro shows here."] =
        "Оберіть заклинання чи предмет, і тут з'явиться макрос.",
    ["In turn, one per press"] = "По черзі, одне за натискання",
    ["One of these at random"] = "Одне з них навмання",
    ["By name"] = "За ім'ям",
    ["Targets the nearest one with this name, when none of the units above is there. Leave On empty (-) to target "
        .. "by name only."] =
        "Бере в ціль найближчого з цим ім'ям, коли нікого з обраних вище немає. Залиште «На кого» порожнім (-), "
        .. "щоб брати в ціль лише за ім'ям.",
    ["Pet"] = "Улюбленець",
    ["On"] = "На кого",
    ["on"] = "на кого",
    ["Then"] = "Далі",
    ["then"] = "далі",
    ["Who the macro casts on. As usual: your target, or you when the game casts on you by itself (Auto Self Cast)."] =
        "На кого макрос застосовує. «Як завжди»: на вашу ціль або на вас, коли гра сама застосовує на вас "
        .. "(Auto Self Cast).",
    ["When the one before is not there, or not the one asked for: this one."] =
        "Коли попереднього немає або він не той, що потрібно: цей.",
    ["Only"] = "Лише",
    ["Anyone there"] = "Будь-хто",
    ["Friends"] = "Друзі",
    ["Enemies"] = "Вороги",
    ["What the units above must be: friends, enemies or anyone there. Yourself, As usual and At the cursor need no "
        .. "check. It follows the spell you pick, when the game knows what it is for; a key's own spell is checked for "
        .. "what it is for."] =
        "Ким мають бути обрані вище: друзями, ворогами чи будь-ким. «Ви самі», «Як завжди» і «Під курсором» не "
        .. "перевіряються. Підлаштовується під обране заклинання, коли гра знає, для кого воно; власне заклинання "
        .. "клавіші перевіряється за тим, для кого воно.",
    ["Alive only"] = "Лише живі",
    ["With a key held"] = "З клавішею",
    ["same spell"] = "те саме заклинання",
    ["On a key macOS uses with Cmd itself (Q quits the game, W, H, Tab, Space...) macOS comes first: the editor "
        .. "warns when the macro sits on one."] =
        "На клавіші, яку macOS сама використовує з Cmd (Q закриває гру, W, H, Tab, Space...), першою спрацьовує "
        .. "macOS: редактор попереджає, коли макрос стоїть на такій.",
    ["Start over"] = "Почати знову",
    ["New target"] = "Нова ціль",
    ["Combat ends"] = "Кінець бою",
    ["What makes the sequence begin again from its first spell: a new target, the end of combat, a press with "
        .. "Shift, Ctrl or Alt held, or some seconds without a press."] =
        "Що змушує послідовність почати знову з першого заклинання: нова ціль, кінець бою, натискання з "
        .. "утриманим Shift, Ctrl чи Alt або кілька секунд без натискань.",
    ["After"] = "Через",
    ["seconds without a press"] = "с без натискань",
    ["Also"] = "Ще",
    ["Stop your cast first"] = "Спершу перервати каст",
    ["For an interrupt or a save: it goes off at once, even in the middle of another cast."] =
        "Для переривання чи порятунку: спрацює одразу, навіть посеред іншого заклинання.",
    ["Trinket 1"] = "Аксесуар 1",
    ["Trinket 2"] = "Аксесуар 2",
    ["Trinket %d: %s"] = "Аксесуар %d: %s",
    ["empty"] = "порожньо",
    ["Your trinkets go off first (/use 13, /use 14), whenever they are ready."] =
        "Спершу спрацьовують ваші аксесуари (/use 13, /use 14), коли вони готові.",
    ["Nearest enemy if none"] = "Найближчий ворог",
    ["When your target is not an enemy, or is dead, the nearest enemy becomes the target first "
        .. "(/targetenemy [noharm][dead])."] =
        "Коли ваша ціль не ворог або мертва, спершу в ціль береться найближчий ворог (/targetenemy [noharm][dead]).",
    ["Start auto attack"] = "Автоатака",
    ["Leave your form first"] = "Спершу вийти з форми",
    ["Out of a form or stance first (/cancelform): to heal out of Bear Form, say."] =
        "Спершу вийти з форми чи стійки (/cancelform): наприклад, щоб лікувати з форми ведмедя.",
    ["Pet attacks your target"] = "Улюбленець атакує ціль",
    ["Off your mount first"] = "Спершу злізти з маунта",
    ["Off the mount first (/dismount [mounted]), so the cast doesn't fail on it."] =
        "Спершу злізти з маунта (/dismount [mounted]), щоб заклинання не зірвалося.",
    ["Cancel a buff"] = "Скасувати бафф",
    ["Cancel a buff first"] = "Спершу скасувати бафф",
    ["the buff's name"] = "назва баффу",
    ["Removes the buff before the rest (/cancelaura Ice Block): leave it empty for none. It offers the buffs on you "
        .. "now and those you have had."] =
        "Знімає бафф перед рештою (/cancelaura Ice Block): залиште порожнім, щоб нічого не знімати. Підказує баффи, "
        .. "які зараз на вас і які були раніше.",
    ["Say in chat"] = "Сказати в чат",
    ["Said after the rest, in the channel on the left; %t is your target's name. Leave it empty to say nothing."] =
        "Кажеться після решти, у каналі ліворуч; %t — ім'я вашої цілі. Залиште порожнім, щоб нічого не казати.",
    ["Create macro"] = "Створити",
    ["Macro"] = "Макрос",
    -- Wizard: step by step (Questions.lua)
    ["Step by step"] = "Покроково",
    ["All options"] = "Усі параметри",
    ["One question at a time, in plain words. What you chose stays."] =
        "По одному питанню за раз, простими словами. Те, що ви вже обрали, лишається.",
    ["The whole form at once, with what you chose so far."] = "Уся форма одразу, з тим, що ви вже обрали.",
    ["< Back"] = "< Назад",
    ["Next >"] = "Далі >",
    ["What should the macro do?"] = "Що має робити макрос?",
    ["Cast a spell"] = "Застосувати заклинання",
    ["Use an item"] = "Використати предмет",
    ["A potion, a healthstone, a toy... or a trinket you wear."] =
        "Зілля, камінь здоров'я, іграшку... або аксесуар, який ви носите.",
    ["Several spells in turn"] = "Кілька заклинань по черзі",
    ["Each press casts the next spell of the list: the first press the first spell, the next press the second, and "
        .. "so on."] =
        "Кожне натискання застосовує наступне заклинання зі списку: перше натискання — перше, наступне — друге і "
        .. "так далі.",
    ["One of several at random"] = "Одне з кількох навмання",
    ["Each press casts one of the spells at random: a random mount, say."] =
        "Кожне натискання застосовує одне із заклинань навмання: наприклад, випадковий маунт.",
    ["Target someone"] = "Взяти когось у ціль",
    ["Set your focus"] = "Задати фокус",
    ["Your focus is a second target to keep an eye on: to interrupt it or keep it crowd controlled while you fight "
        .. "another."] =
        "Фокус — це друга ціль, за якою ви стежите: щоб перебити її каст чи тримати під контролем, поки б'єтеся з "
        .. "іншою.",
    ["Take someone's target"] = "Взяти чужу ціль",
    ["Your target becomes the target of someone else: the tank's, say."] =
        "Вашою ціллю стає ціль когось іншого: наприклад, танка.",
    ["Command your pet"] = "Керувати улюбленцем",
    ["Tell your pet to attack, follow you, stay..."] = "Накажіть улюбленцю атакувати, іти за вами, стояти...",
    ["Which spell should the macro cast?"] = "Яке заклинання має застосовувати макрос?",
    ["Which item should the macro use?"] = "Який предмет має використовувати макрос?",
    ["Start typing its name, or pick it from the list."] = "Почніть вводити назву або оберіть зі списку.",
    ["What should the macro cast instead?"] = "Що макрос має застосовувати замість цього?",
    ["Leave it empty for the same one, on someone else."] =
        "Залиште порожнім, щоб застосовувати те саме, але на когось іншого.",
    ["Pick the spells in the order the macro should cast them"] =
        "Оберіть заклинання в тому порядку, в якому макрос має їх застосовувати",
    ["One per press: the first press casts the first spell, the next press the second, and so on."] =
        "По одному за натискання: перше натискання — перше заклинання, наступне — друге і так далі.",
    ["Pick the spells the macro chooses from"] = "Оберіть заклинання, з яких макрос вибиратиме",
    ["Each press casts one of them at random."] = "Кожне натискання — одне з них навмання.",
    ["When should the sequence start again from the first spell?"] =
        "Коли послідовність має починатися знову з першого заклинання?",
    ["Pick any of these, or none: then it starts again only after the last spell."] =
        "Оберіть що завгодно з цього або нічого: тоді вона почнеться знову лише після останнього заклинання.",
    ["When you take a new target"] = "Коли ви берете нову ціль",
    ["When combat ends"] = "Коли закінчується бій",
    ["When you press it with %s held"] = "Коли натискаєте його із затиснутим %s",
    ["What should your pet do?"] = "Що має робити ваш улюбленець?",
    ["Where should %s go?"] = "На кого чи куди застосувати «%s»?",
    ["Where should these spells go?"] = "На кого чи куди застосовувати ці заклинання?",
    ["Who should become your target?"] = "Хто має стати вашою ціллю?",
    ["Who should become your focus?"] = "Хто має стати вашим фокусом?",
    ["Whose target should you take?"] = "Хто вибирає ціль для вас?",
    ["Who should your pet attack?"] = "Хто має стати ціллю вашого улюбленця?",
    ["Friends or enemies?"] = "Друзі чи вороги?",
    ["Who is %s for?"] = "Для кого «%s»?",
    ["Who are these spells for?"] = "Для кого ці заклинання?",
    ["Friends, dead or alive"] = "Друзі, живі чи мертві",
    ["For a resurrection."] = "Для воскресіння.",
    ["On your target, as usual"] = "На вашу ціль, як завжди",
    ["On your target, if a friend"] = "На вашу ціль, якщо це друг",
    ["On your target, if an enemy"] = "На вашу ціль, якщо це ворог",
    ["On your target, if there is one"] = "На вашу ціль, якщо вона є",
    ["On whoever is under the mouse"] = "На того, хто під мишею",
    ["On the ground under the cursor"] = "На землю під курсором",
    ["On yourself"] = "На себе",
    ["On your focus"] = "На ваш фокус",
    ["On your pet"] = "На вашого улюбленця",
    ["On your target's target"] = "На ціль вашої цілі",
    ["On party member %d"] = "На члена групи %d",
    ["On arena enemy %d"] = "На ворога на арені %d",
    ["Your target, as usual"] = "Ваша ціль, як завжди",
    ["Your target, if a friend"] = "Ваша ціль, якщо це друг",
    ["Your target, if an enemy"] = "Ваша ціль, якщо це ворог",
    ["Your target, if there is one"] = "Ваша ціль, якщо вона є",
    ["Whoever is under the mouse"] = "Той, хто під мишею",
    ["Your focus"] = "Ваш фокус",
    ["Your target's target"] = "Ціль вашої цілі",
    ["Party member %d"] = "Член групи %d",
    ["Arena enemy %d"] = "Ворог на арені %d",
    ["Do nothing"] = "Нічого не робити",
    ["Someone by name"] = "Хтось за ім'ям",
    ["The game's own choice: your target, or you when the game casts on you by itself (Auto Self Cast)."] =
        "Як вирішить гра: на вашу ціль або на вас, коли гра сама застосовує на вас (Auto Self Cast).",
    ["The one your mouse points at, in the world or on a frame (party, raid). Your target stays as it is."] =
        "Той, на кого вказує миша, у світі чи на рамці (група, рейд). Ваша ціль при цьому не змінюється.",
    ["For spells cast on the ground, like Blizzard: it lands under the cursor at once, with no circle to place."] =
        "Для заклинань на землю, як Blizzard: воно впаде під курсор одразу, без кола, яке треба ставити.",
    ["A second target you keep an eye on; /focus sets it."] = "Друга ціль, за якою ви стежите; її задає /focus.",
    ["Whoever your target has targeted: the one a boss attacks, say."] =
        "Той, кого взяла в ціль ваша ціль: наприклад, той, кого б'є бос.",
    ["Your party members, as your party frames list them from the top."] =
        "Члени вашої групи в тому порядку, як їх показують рамки групи згори.",
    ["The enemies of an arena match, in the order of their frames."] = "Вороги на арені в порядку їхніх рамок.",
    ["And if nobody is under the mouse?"] = "А якщо під мишею нікого немає?",
    ["And if you have no target?"] = "А якщо у вас немає цілі?",
    ["And if you have no focus?"] = "А якщо у вас немає фокуса?",
    ["And if your pet is not out?"] = "А якщо улюбленця немає поруч?",
    ["And if your target has no target?"] = "А якщо у вашої цілі немає цілі?",
    ["And if party member %d is not there?"] = "А якщо члена групи %d немає?",
    ["And if arena enemy %d is not there?"] = "А якщо ворога на арені %d немає?",
    ["Or the one there is not a friend, or is dead."] = "Або той, хто там є, не друг чи мертвий.",
    ["Or the one there is not a friend."] = "Або той, хто там є, не друг.",
    ["Or the one there is not an enemy, or is dead."] = "Або той, хто там є, не ворог чи мертвий.",
    ["Or the one there is not an enemy."] = "Або той, хто там є, не ворог.",
    ["Or the one there is dead."] = "Або той, хто там є, мертвий.",
    ["What name should it look for?"] = "Яке ім'я шукати?",
    ["The nearest one with this name becomes your target: a rare, say."] =
        "Вашою ціллю стане найближчий з таким ім'ям: наприклад, рідкісний монстр.",
    ["Should the macro do something else while you hold %s?"] =
        "Чи має макрос робити щось інше, поки ви тримаєте %s?",
    ["Pick the keys, or none: for each one, the next questions ask what it does."] =
        "Оберіть клавіші або жодної: для кожної далі буде питання, що вона робить.",
    ["With %s held"] = "Із затиснутим %s",
    ["Would you like to add anything else?"] = "Бажаєте додати ще щось?",
    ["Pick any of these, or none."] = "Оберіть що завгодно з цього або нічого.",
    ["Which rank of %s?"] = "Який ранг «%s»?",
    ["The highest you know"] = "Найвищий, який ви знаєте",
    ["Usually the highest you know: it follows when you learn a new one."] =
        "Зазвичай найвищий, який ви знаєте: він сам оновиться, коли ви вивчите новий.",
    ["highest rank"] = "найвищий ранг",
    ["Almost done: name your macro"] = "Майже готово: назвіть макрос",
    ["Then drag its icon from the editor onto an action bar."] =
        "Потім перетягніть його іконку з редактора на панель дій.",
    ["For all your characters"] = "Для всіх ваших персонажів",
    ["Only for this character"] = "Лише для цього персонажа",
    -- Wizard: its lists (Wizard.lua)
    ["Pet commands"] = "Команди улюбленця",
    ["Attack"] = "Атакувати",
    ["Follow"] = "За мною",
    ["Stay"] = "Стояти",
    ["Move to the cursor"] = "Іти до курсора",
    ["Passive"] = "Пасивний",
    ["Defensive"] = "Захисний",
    ["Aggressive"] = "Агресивний",
    ["Dismiss"] = "Відпустити",
    ["Say"] = "Сказати",
    ["Yell"] = "Крикнути",
    ["Party"] = "Група",
    ["Raid"] = "Рейд",
    ["Emote"] = "Емоція",
    ["As usual"] = "Як завжди",
    ["Your target"] = "Ваша ціль",
    ["Mouseover"] = "Маусовер",
    ["Focus"] = "Фокус",
    ["Yourself"] = "Ви самі",
    ["Your pet"] = "Ваш улюбленець",
    ["Party member 1"] = "Член групи 1",
    ["Party member 2"] = "Член групи 2",
    ["Party member 3"] = "Член групи 3",
    ["Party member 4"] = "Член групи 4",
    ["Target's target"] = "Ціль цілі",
    ["Arena enemy 1"] = "Ворог на арені 1",
    ["Arena enemy 2"] = "Ворог на арені 2",
    ["Arena enemy 3"] = "Ворог на арені 3",
    ["At the cursor"] = "Під курсором",
    ["Clear focus"] = "Зняти фокус",
    ["Clear target"] = "Зняти ціль",
    -- the names the wizard gives a macro that casts nothing of its own
    ["Target"] = "Ціль",
    ["Assist"] = "Допомога",
    ["Trinkets"] = "Аксесуари",
    -- Checks of the macro text
    ["unknown command \"/%s\""] = "невідома команда «/%s»",
    ["\"/%s\" does nothing in this version of the game (it came with a later one)"] =
        "«/%s» нічого не робить у цій версії гри (з'явилася в пізнішій)",
    ["not in this game version"] = "немає в цій версії гри",
    ["unknown condition \"%s\""] = "невідома умова «%s»",
    ["%s: needs a value"] = "%s: потрібне значення",
    ["%s takes no value"] = "%s не приймає значення",
    ["invalid %s value \"%s\" (expected %s)"] = "неправильне значення %s «%s» (очікується %s)",
    ["invalid reset value \"%s\" (expected seconds, target, combat, shift, ctrl or alt)"] =
        "неправильне значення reset «%s» (очікуються секунди, target, combat, shift, ctrl чи alt)",
    ["unknown unit \"%s\" (fine if it is a player's name)"] = "невідома ціль «%s» (нічого, якщо це ім'я гравця)",
    ["@ needs a unit"] = "@ потребує цілі",
    ["target= needs a unit"] = "target= потребує цілі",
    ["[ is not closed with ]"] = "[ не закрито ]",
    ["] without ["] = "] без [",
    ["empty condition"] = "порожня умова",
    ["no equipment slot %s (1-19)"] = "немає слоту спорядження %s (1-19)",
    ["item: needs an item number, like item:6948"] = "item: потребує номера предмета, як item:6948",
    ["the item is missing after the slot"] = "після слоту бракує предмета",
    ["/equipslot needs the slot first, like /equipslot 13 Name"] =
        "/equipslot спершу потребує слот, як /equipslot 13 Name",
    ["reset= works only in /castsequence"] = "reset= працює лише в /castsequence",
    ["reset= needs a value"] = "reset= потребує значення",
    ["unknown name \"%s\", did you mean \"%s\"?"] = "невідома назва «%s», можливо, «%s»?",
    ["unknown mouse button \"%s\", did you mean \"%s\"?"] = "невідома кнопка миші «%s», можливо, «%s»?",
    ["did you mean \"%s\"?"] = "можливо, «%s»?",
    -- a spell of yours the game can't cast now (Sources.lua)
    ["\"%s\": a talent you haven't chosen, the macro can't use it now"] =
        "«%s»: талант не вибрано, макрос зараз не може його використати",
    ["talent not chosen"] = "талант не вибрано",
    ["\"%s\" belongs to %s: you are in another specialization now"] =
        "«%s» належить до %s: зараз у вас інша спеціалізація",
    ["%s only"] = "лише для %s",
    ["\"%s\": you learn it at level %d"] = "«%s»: ви вивчите його на %d рівні",
    ["\"%s\": you haven't learned it yet"] = "«%s»: ви його ще не вивчили",
    ["not learned yet"] = "ще не вивчено",
    ["the game reads \"%s\" as no: true clicks on key press"] =
        "гра читає «%s» як «ні»: true натискає при натисканні клавіші",
    ["no button \"%s\" now (an addon may make it later)"] = "зараз немає кнопки «%s» (аддон може створити її пізніше)",
    ["no such button now"] = "такої кнопки зараз немає",
    ["\"%s\" is not a button /click can click"] = "«%s» — не кнопка, яку може натиснути /click",
    ["not a button /click can click"] = "не кнопка для /click",
    -- the values a condition expects (Conditions.lua)
    ["shift, ctrl, alt or a key action like SELFCAST"] = "shift, ctrl, alt або дія клавіші, як SELFCAST",
    ["1-5 or a button name"] = "1-5 або назва кнопки",
    ["party or raid"] = "party або raid",
    ["a bar page 1-6"] = "сторінка панелі 1-6",
    ["a form number, 0 = no form"] = "номер форми, 0 — без форми",
    ["a specialization number"] = "номер спеціалізації",

    -- Live preview
    ["runs"] = "виконує",
    ["icon: "] = "іконка: ",
    ["stops here"] = "зупиняється тут",
    ["does nothing"] = "нічого не робить",
    ["conditions not met"] = "умови не виконано",
    ["says it in chat"] = "пише в чат",
    ["not reached"] = "не дійде",
    ["equip"] = "вдягає",
    ["cancel"] = "скасовує",
    ["slot %s"] = "слот %s",
    ["bag %s, slot %s"] = "сумка %s, слот %s",

    -- macOS shortcuts
    ["%s is a macOS shortcut (%s)"] = "%s — сполучення клавіш macOS (%s)",
    ["%s are macOS shortcuts"] = "%s — сполучення клавіш macOS",
    ["quits the game"] = "закриває гру",
    ["closes the window"] = "закриває вікно",
    ["hides the game"] = "ховає гру",
    ["minimizes the window"] = "згортає вікно",
    ["switches apps"] = "перемикає програми",
    ["opens Spotlight"] = "відкриває Spotlight",
    ["switches windows"] = "перемикає вікна",
    ["hides other apps"] = "ховає інші програми",
    ["minimizes all windows"] = "згортає всі вікна",
    ["toggles the Dock"] = "показує чи ховає Dock",
    ["opens Force Quit"] = "відкриває примусове завершення",
    ["locks the screen"] = "блокує екран",
    ["toggles full screen"] = "вмикає чи вимикає повноекранний режим",
    ["opens emoji"] = "відкриває емодзі",
    ["logs you out"] = "завершує сеанс",
    ["takes a screenshot"] = "робить знімок екрана",
    ["opens screenshot tools"] = "відкриває інструменти знімків екрана",

    -- Action bars, minimap button, icon picker
    ["Shift + right-click: edit in MacroSense"] = "Shift + правий клік: редагувати в MacroSense",
    ["Click: open or close the editor"] = "Клацання: відкрити чи закрити редактор",
    ["Drag: move the button"] = "Перетягування: перемістити кнопку",
    ["/ms minimap hides it"] = "/ms minimap ховає її",
    ["No icons"] = "Немає іконок",
    ["%d icons"] = { "%d іконка", "%d іконки", "%d іконок" },
    ["%s (looking up names: %d%%)"] = "%s (шукаю назви: %d%%)",
    ["Search by name"] = "Пошук за назвою",

    -- Autocomplete: what each suggestion is (Data.lua, Sources.lua)
    ["icon + tooltip of a spell"] = "іконка й підказка заклинання",
    ["icon of a spell"] = "іконка заклинання",
    ["cast a spell"] = "застосувати заклинання",
    ["use an item or spell"] = "використати предмет чи заклинання",
    ["cast spells in order"] = "заклинання по черзі",
    ["cast a random spell"] = "випадкове заклинання",
    ["use a random item"] = "випадковий предмет",
    ["stop the current cast"] = "перервати поточний каст",
    ["stop the macro"] = "зупинити макрос",
    ["start auto attack"] = "почати автоатаку",
    ["stop auto attack"] = "зупинити автоатаку",
    ["remove a buff"] = "зняти бафф",
    ["leave the current form"] = "вийти з поточної форми",
    ["target a unit"] = "взяти в ціль",
    ["next enemy"] = "наступний ворог",
    ["next friend"] = "наступний друг",
    ["previous target"] = "попередня ціль",
    ["clear the target"] = "зняти ціль",
    ["target of a unit"] = "ціль когось",
    ["set focus"] = "задати фокус",
    ["clear focus"] = "зняти фокус",
    ["pet attacks"] = "улюбленець атакує",
    ["pet follows"] = "улюбленець іде за вами",
    ["pet stays"] = "улюбленець стоїть",
    ["pet passive"] = "улюбленець пасивний",
    ["pet defensive"] = "улюбленець захищається",
    ["pet assist"] = "улюбленець допомагає",
    ["equip an item"] = "вдягнути предмет",
    ["equip into a slot"] = "вдягнути в слот",
    ["click a button"] = "натиснути кнопку",
    ["leave the mount"] = "злізти з маунта",
    ["leave the vehicle"] = "вийти з транспорту",
    ["run Lua"] = "виконати Lua",
    ["chat"] = "чат",
    ["in combat"] = "у бою",
    ["out of combat"] = "поза боєм",
    ["modifier held"] = "утримано модифікатор",
    ["no modifier held"] = "модифікатор не утримано",
    ["unit is hostile"] = "ворожий",
    ["unit is friendly"] = "дружній",
    ["unit exists"] = "існує",
    ["unit does not exist"] = "не існує",
    ["unit is dead"] = "мертвий",
    ["unit is alive"] = "живий",
    ["target unit"] = "на кого",
    ["stance / form"] = "стійка / форма",
    ["no form"] = "без форми",
    ["stealthed"] = "у непомітності",
    ["on a mount"] = "на маунті",
    ["flying"] = "у польоті",
    ["flying allowed"] = "можна літати",
    ["skyriding allowed"] = "можна skyriding",
    ["swimming"] = "пливе",
    ["indoors"] = "у приміщенні",
    ["outdoors"] = "надворі",
    ["in a rested area"] = "у зоні відпочинку",
    ["channeling a spell"] = "триває потокове заклинання",
    ["in a group"] = "у групі",
    ["pet is out"] = "улюбленець поруч",
    ["no pet"] = "немає улюбленця",
    ["active specialization"] = "активна спеціалізація",
    ["spell is known"] = "заклинання відоме",
    ["talent row/column"] = "талант: ряд/стовпець",
    ["pvp talent"] = "PvP-талант",
    ["item type equipped"] = "вдягнено тип предмета",
    ["mouse button"] = "кнопка миші",
    ["action bar page"] = "сторінка панелі дій",
    ["bonus bar"] = "бонусна панель",
    ["extra action bar"] = "додаткова кнопка дії",
    ["override bar"] = "панель заміни",
    ["possess bar"] = "панель контролю",
    ["in a vehicle"] = "у транспорті",
    ["unit in a vehicle"] = "ціль у транспорті",
    ["can leave vehicle"] = "можна вийти з транспорту",
    ["in a pet battle"] = "у битві вихованців",
    ["holding something on cursor"] = "щось на курсорі",
    ["left"] = "лів.",
    ["right"] = "прав.",
    ["middle"] = "серед.",
    ["on key press"] = "при натисканні клавіші",
    ["new target"] = "нова ціль",
    ["combat ends"] = "кінець бою",
    ["with Shift"] = "з Shift",
    ["with Ctrl"] = "з Ctrl",
    ["with Alt"] = "з Alt",
    ["seconds idle"] = "с бездіяльності",
    ["Head"] = "Голова",
    ["Neck"] = "Шия",
    ["Shoulder"] = "Плечі",
    ["Shirt"] = "Сорочка",
    ["Chest"] = "Груди",
    ["Waist"] = "Пояс",
    ["Legs"] = "Ноги",
    ["Feet"] = "Ступні",
    ["Wrist"] = "Зап'ястя",
    ["Hands"] = "Руки",
    ["Finger 1"] = "Палець 1",
    ["Finger 2"] = "Палець 2",
    ["Back"] = "Спина",
    ["Main Hand"] = "Права рука",
    ["Off Hand"] = "Ліва рука",
    ["Ranged"] = "Дальній бій",
    ["Tabard"] = "Гербова накидка",
    ["ground at cursor"] = "земля під курсором",
    ["no target"] = "без цілі",
    ["NPC you talk to"] = "NPC, з яким ви говорите",
    ["highest"] = "найвищий",
    ["equipped"] = "вдягнено",
    ["item"] = "предмет",
    ["primary"] = "основна",
    ["secondary"] = "додаткова",
    ["your pet"] = "ваш улюбленець",
    ["pet family"] = "родина улюбленця",
    ["extra action"] = "додаткова дія",
    ["popup: first button"] = "вікно: перша кнопка",
    ["popup: second button"] = "вікно: друга кнопка",
    ["on you now"] = "зараз на вас",
    ["buff"] = "бафф",
}
