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
    ["  Or in the comments on CurseForge, or by email: %s"] = "  Або в коментарях на CurseForge, або на пошту: %s",
    ["|cff00ff00on|r"] = "|cff00ff00увімк.|r",
    ["|cffff0000off|r"] = "|cffff0000вимк.|r",
    ["autocomplete %s"] = "автодоповнення: %s",
    ["minimap button %s"] = "кнопка біля мінікарти: %s",
    ["bug report details:"] = "подробиці для звіту про помилку:",
    ["  Please describe what you did, what you expected and what happened; a screenshot helps."] =
        "  Опишіть, що ви робили, чого очікували і що сталося; знімок екрана теж допоможе.",
    ["debug %s"] = "налагодження: %s",
    ["/ms - open the editor; /ms help - the macro guide; /ms minimap - hide or show the minimap button; "
        .. "/ms bug - details for a bug report; /ms autocomplete | debug - toggle"] =
        "/ms — відкрити редактор; /ms help — довідка з макросів; /ms minimap — сховати чи показати кнопку біля "
        .. "мінікарти; /ms bug — подробиці для звіту про помилку; /ms autocomplete | debug — увімкнути чи вимкнути",
    ["Only turns it on, never off. A press turns some spells on and off: Shoot, Auto Shot, Stealth, Prowl, a form. "
        .. "With !, a press while it is on keeps it on: !Shoot doesn't stop your shooting, !Stealth doesn't take you "
        .. "out of stealth."] =
        "Лише вмикає, ніколи не вимикає. Деякі заклинання одне натискання вмикає, а наступне вимикає: Shoot, Auto "
        .. "Shot, Stealth, Prowl, форми. Із ! натискання, коли воно вже увімкнене, нічого не вимикає: !Shoot не "
        .. "зупиняє стрільбу, !Stealth не виводить зі стелсу.",
    ["%s (only turns it on)"] = "%s (лише вмикає)",
    -- The macro guide (HelpWindow)
    ["Macro guide"] = "Довідка з макросів",
    ["What macros are, what they can do and how to make them, with ready-made macros."] =
        "Що таке макроси, що вони вміють і як їх робити, з готовими макросами.",
    ["What a macro is"] = "Що таке макрос",
    ["A macro is a button that does several things at once, or a different thing depending on the moment. You put it "
        .. "on an action bar like a spell and press it the same way. Inside are lines of text, one command each:"] =
        "Макрос — це кнопка, яка робить кілька речей одразу або різне залежно від ситуації. Її ставлять на панель "
        .. "дій, як заклинання, і натискають так само. Усередині — рядки тексту, по одній команді в кожному:",
    ["Press it, and the game reads the lines from the top and does what they say: here, it casts Fireball."] =
        "Коли ви натискаєте макрос, гра читає рядки згори вниз і робить, що в них написано. Тут — кастує Fireball.",
    ["General macros, up to 120, are the same for every character on your account. Character macros, up to 30, "
        .. "belong to the character you play. A macro holds at most 255 characters, about five or six lines."] =
        "Загальних макросів може бути до 120, і вони однакові для всіх персонажів облікового запису. Макросів "
        .. "персонажа — до 30, і вони лише для персонажа, яким ви граєте. Макрос має щонайбільше 255 символів, це "
        .. "приблизно п'ять-шість рядків.",
    ["Your first macro"] = "Перший макрос",
    ["Let's make a macro that casts Shadow Bolt at the enemy under your mouse, or at your target when you point at "
        .. "nobody. Swap in any spell of yours."] =
        "Зробімо макрос, який кастує Shadow Bolt у ворога під мишею, а якщо там нікого немає — у вашу ціль. Замість "
        .. "Shadow Bolt можна взяти будь-яке своє заклинання.",
    ["Pick the Character tab and press New under the list. The new macro already has #showtooltip on its first line, "
        .. "and the cursor waits on the second."] =
        "Виберіть вкладку «Персонаж» і натисніть «Новий» під списком. У новому макросі вже є #showtooltip у першому "
        .. "рядку, а курсор стоїть на другому.",
    ["Type a name at the top, such as Bolt MO (MO for mouseover), and press Tab."] =
        "Угорі введіть назву, наприклад Bolt MO (MO — це mouseover, «під мишею»), і натисніть Tab.",
    ["Type /ca and take /cast from the list with Tab. Type [@ and pick mouseover, then type ,harm and ]. Then a few "
        .. "letters of the spell, and pick it."] =
        "Наберіть /ca і вставте /cast зі списку клавішею Tab. Наберіть [@ і виберіть mouseover, потім наберіть ,harm "
        .. "і ]. Далі кілька літер заклинання, і виберіть його.",
    ["Add [] before the spell name. It means \"otherwise, as usual\", so with nobody under the mouse the spell goes to "
        .. "your target:"] =
        "Додайте [] перед назвою заклинання. Це означає «інакше — як зазвичай», тож коли під мишею нікого немає, "
        .. "заклинання полетить у вашу ціль:",
    ["Next to the line, the editor shows what it would do right now. Point at the line's number to read the whole "
        .. "line in plain words."] =
        "Біля рядка редактор показує, що той зробив би прямо зараз. Наведіть мишу на номер рядка, щоб прочитати весь "
        .. "рядок простими словами.",
    ["Press Save, then drag the macro from the list onto an action bar. Done."] =
        "Натисніть «Зберегти» і перетягніть макрос зі списку на панель дій. Готово.",
    ["New macro"] = "Новий макрос",
    ["The wizard"] = "Майстер",
    ["You don't have to write anything: New (Wizard) under the list makes the macro for you."] =
        "Писати нічого не обов'язково: «Майстер» під списком зробить макрос за вас.",
    ["Step by step, it asks one question at a time: what the macro should do, which spell, on whom, and if not, on "
        .. "whom then, what Shift, Ctrl or Alt change, when it works. All options in its title bar shows the whole "
        .. "form at once instead."] =
        "Покроково він ставить по одному питанню: що має робити макрос, яке заклинання, на кого, а якщо ні — то на "
        .. "кого тоді, що змінюють Shift, Ctrl чи Alt, коли він працює. «Усі параметри» в його заголовку натомість "
        .. "показують усю форму одразу.",
    ["The macro grows at the bottom of the wizard as you answer. Create macro saves it and opens it in the editor."] =
        "Поки ви відповідаєте, макрос з'являється внизу майстра. «Створити» зберігає його й відкриває в редакторі.",
    ["To change a macro you have with the same questions, open it and press Wizard above its text."] =
        "Щоб змінити наявний макрос тими самими питаннями, відкрийте його й натисніть «У майстрі» над текстом.",
    ["Open the wizard"] = "Відкрити майстра",
    ["How a line reads"] = "Як читається рядок",
    ["The command: what to do. /cast casts a spell, /use uses an item."] =
        "Команда: що зробити. /cast кастує заклинання, /use використовує предмет.",
    ["Conditions: when this part works. All of them in one pair of brackets must be true."] =
        "Умови: коли ця частина спрацьовує. Усі умови в одних дужках мають виконуватися разом.",
    ["On whom. Without it, the spell goes to your target as usual."] =
        "На кого. Без цього заклинання йде у вашу ціль, як зазвичай.",
    ["The spell or item."] = "Заклинання чи предмет.",
    ["Otherwise: the game tries the next part."] = "Інакше: гра пробує наступну частину.",
    ["Two pairs of brackets in a row: this, or else that, for the same spell."] =
        "Дві пари дужок поспіль: це, а якщо ні — то те, для того самого заклинання.",
    ["Empty brackets are always true: otherwise, as usual."] =
        "Порожні дужки виконуються завжди: інакше — як зазвичай.",
    ["Only turns it on: a press doesn't stop your shooting or take you out of stealth."] =
        "Лише вмикає: натискання не зупиняє стрільбу й не виводить зі стелсу.",
    ["A setting, not a command: the macro shows the tooltip of what it would cast, and its icon while the macro's "
        .. "icon is the question mark."] =
        "Налаштування, а не команда: макрос показує підказку того, що скастує, а поки іконка макросу — знак питання, "
        .. "то й його іконку.",
    ["How the game picks"] = "Як гра вибирає",
    ["On each line, the game reads the parts from left to right and takes the first one whose conditions are all "
        .. "true. The rest of the line is skipped."] =
        "У кожному рядку гра читає частини зліва направо й бере першу, усі умови якої виконуються. Решту рядка вона "
        .. "пропускає.",
    ["Is Shift held, and do you have a focus? Then Polymorph on your focus."] =
        "Затиснуто Shift і у вас є фокус? Тоді Polymorph на ваш фокус.",
    ["If not: is there an enemy under the mouse? Then Frostbolt on it."] =
        "Якщо ні: під мишею є ворог? Тоді Frostbolt у нього.",
    ["If not: Frostbolt on your target."] = "Якщо ні: Frostbolt у вашу ціль.",
    ["So put the special cases first and the usual one last."] =
        "Тож особливі випадки ставте першими, а звичайний — останнім.",
    ["One press casts only one spell that starts the global cooldown. Lines after it still run if they don't need "
        .. "it: /startattack, a trinket, a chat line."] =
        "Одне натискання кастує лише одне заклинання, яке запускає глобальний кулдаун. Рядки після нього все одно "
        .. "виконуються, якщо кулдаун їм не потрібен: /startattack, трінкет, рядок у чат.",
    ["What macros can do"] = "Що вміють макроси",
    ["Type / in the editor to see every command your game has, addons' too. Point at a command to read what it does."] =
        "Наберіть / у редакторі, і побачите всі команди вашої гри, зокрема й команди аддонів. Наведіть мишу на "
        .. "команду, щоб прочитати, що вона робить.",
    ["Conditions and units"] = "Умови та юніти",
    ["Each condition works the other way round with no in front: nocombat, nomod, nodead."] =
        "Кожна умова працює й навпаки, якщо додати no спереду: nocombat, nomod, nodead.",
    ["The units, for @:"] = "Юніти для @:",
    ["Type [ in the editor for every condition, and [@ for every unit."] =
        "Наберіть [ у редакторі, щоб побачити всі умови, і [@ — усі юніти.",
    ["What macros can't do"] = "Чого макроси не вміють",
    ["Think for you"] = "Думати за вас",
    ["A macro can't check your health, a cooldown or how long a buff lasts. It knows only what conditions can say."] =
        "Макрос не може перевірити ваше здоров'я, кулдаун чи скільки ще триватиме баф. Він знає лише те, що можуть "
        .. "сказати умови.",
    ["Cast at once"] = "Кастувати все одразу",
    ["One spell with the global cooldown per press."] = "Одне заклинання з глобальним кулдауном за одне натискання.",
    ["Press itself"] = "Натискатися самостійно",
    ["Every cast needs your key press or click."] = "Кожен каст потребує вашого натискання клавіші чи клацання.",
    ["Be long"] = "Бути довгим",
    ["255 characters at most. Shorten at the top writes the same macro in fewer."] =
        "Щонайбільше 255 символів. «Скоротити» вгорі записує той самий макрос коротше.",
    ["Cast from /run"] = "Кастувати з /run",
    ["Lua in a macro can't cast or target."] = "Lua в макросі не може кастувати чи брати в ціль.",
    ["Ready-made macros"] = "Готові макроси",
    ["Create puts the macro into the tab that is open, under a free name, and opens it. Change the spell names to "
        .. "yours."] =
        "«Створити» додає макрос у відкриту вкладку під вільною назвою й відкриває його. Замініть назви заклинань на "
        .. "свої.",
    ["Heal whoever is under the mouse; if nobody, your target if it is a friend; if not, you:"] =
        "Лікує того, хто під мишею; якщо там нікого — вашу ціль, якщо вона друг; інакше — вас:",
    ["Interrupt your focus, or your target:"] = "Переривання фокуса або цілі:",
    ["Another spell with Shift held:"] = "Інше заклинання із затиснутим Shift:",
    ["A trinket with your big spell:"] = "Трінкет разом із великим заклинанням:",
    ["Two curses in turn, from the start on a new target:"] = "Два прокляття по черзі, з початку на новій цілі:",
    ["Shoot with a wand, and keep shooting however often you press:"] =
        "Стрільба з жезла, яку не зупиняють повторні натискання:",
    ["The pet attacks what you point at, and follows you with Shift:"] =
        "Улюбленець атакує того, на кого ви наводите мишу, а з Shift іде за вами:",
    ["One mount button:"] = "Одна кнопка для всіх маунтів:",
    ["Create"] = "Створити",
    ["Typing less"] = "Менше набирати",
    ["The list that comes up as you type doesn't need the whole word, or even its start:"] =
        "Списку, що з'являється, поки ви пишете, не потрібне ціле слово і навіть не обов'язково його початок:",
    ["Shadow Bolt: capitals are the first letters of the words."] = "Shadow Bolt: великі літери — перші літери слів.",
    ["Curse of Agony: small words may be left out, or typed in small letters."] =
        "Curse of Agony: короткі слова можна пропустити або набрати малими.",
    ["Shadow Word: Pain: a space goes on to the next word."] =
        "Shadow Word: Pain: пробіл переходить до наступного слова.",
    ["nocombat: letters in order, from the start of the word, with others between them."] =
        "nocombat: літери по порядку від початку слова, з іншими між ними.",
    ["mounted: the same for conditions, commands and units."] = "mounted: так само для умов, команд і юнітів.",
    ["Tab or Enter takes the highlighted one, Up and Down move through the list, Esc closes it."] =
        "Tab або Enter вставляє виділене, стрілки вгору й униз гортають список, Esc його закриває.",
    ["The full guide"] = "Повний гайд",
    ["The full guide, with pictures and more examples, is on GitHub. Copy the link and open it in your browser:"] =
        "Повний гайд з ілюстраціями та іншими прикладами — на GitHub. Скопіюйте посилання й відкрийте його в "
        .. "браузері:",
    ["%s copies it; open it in your browser."] = "%s копіює посилання; відкрийте його в браузері.",

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
    ["See exactly how the macro will act. Next to each line is what it would do if you pressed the macro now."] =
        "Тут видно, як саме діятиме макрос. Біля кожного рядка написано, що він зробить, якщо натиснути макрос зараз.",
    ["Hold %s, point the mouse at someone, change your target. Try everything the macro checks, and you see which "
        .. "ability it uses and when."] =
        "Затисніть %s, наведіть мишу на когось, змініть ціль. Спробуйте все, що перевіряє макрос, і побачите, що й "
        .. "коли він застосує.",
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
    ["Move to Character"] = "Перенести в «Персонаж»",
    ["Move to General"] = "Перенести в «Загальні»",
    ["Into the Character tab, for this character only. Its buttons on your action bars stay, and its history goes "
        .. "with it."] =
        "У вкладку «Персонаж», лише для цього персонажа. Його кнопки на ваших панелях дій лишаються, а історія "
        .. "переходить разом із ним.",
    ["Into the General tab, for all your characters. Its buttons on your action bars stay, and its history goes "
        .. "with it."] =
        "У вкладку «Загальні», для всіх ваших персонажів. Його кнопки на ваших панелях дій лишаються, а історія "
        .. "переходить разом із ним.",
    ["Move \"%s\" to the General tab?%s"] = "Перенести «%s» у вкладку «Загальні»?%s",
    ["Move \"%s\" to the Character tab?%s"] = "Перенести «%s» у вкладку «Персонаж»?%s",
    ["It will be gone from the bars of %s."] = "З панелей %s він зникне.",
    ["Move"] = "Перенести",
    ["could not move the macro"] = "не вдалося перенести макрос",
    -- other characters' macros, in the Character tab
    ["Its own macros, as they were when you last played it: %s. Click to show or hide them."] =
        "Його власні макроси, якими вони були, коли ви востаннє ним грали: %s. Клацніть, щоб показати чи "
        .. "сховати їх.",
    ["A macro of %s. Click to copy it."] = "Макрос персонажа %s. Клацніть, щоб скопіювати його.",
    ["Forget this character"] = "Забути цього персонажа",
    ["Forget %s? MacroSense no longer shows its macros or counts its action bars, until you log in with it again."] =
        "Забути %s? MacroSense більше не показуватиме його макроси й не враховуватиме його панелі дій, доки ви знову "
        .. "не зайдете ним у гру.",
    ["Forget"] = "Забути",
    ["Log in with your other characters once, and their own macros show up here to copy."] =
        "Зайдіть у гру іншими персонажами хоч раз, і їхні власні макроси з'являться тут, щоб їх можна було скопіювати.",
    -- where a macro is on the action bars
    ["Not on action bars"] = "Не на панелях дій",
    ["Only the macros you have put on no action bar: handy to free slots. MacroSense remembers the bars of each of "
        .. "your specializations and characters as it last saw them, so a general macro an alt uses counts as used."] =
        "Лише макроси, яких немає на жодній панелі дій: зручно, щоб звільнити слоти. MacroSense пам'ятає панелі "
        .. "кожної вашої спеціалізації та кожного персонажа такими, якими бачив їх востаннє, тож загальний макрос, "
        .. "яким користується альт, теж вважається потрібним.",
    ["On %d buttons of your action bars"] = { "На %d кнопці ваших панелей дій", "На %d кнопках ваших панелей дій",
        "На %d кнопках ваших панелей дій" },
    ["Not on your action bars now"] = "Зараз його немає на ваших панелях дій",
    ["On the bars of %s"] = "На панелях: %s",
    ["It is on %d buttons of your action bars."] = { "Він стоїть на %d кнопці ваших панелей дій.",
        "Він стоїть на %d кнопках ваших панелей дій.", "Він стоїть на %d кнопках ваших панелей дій." },
    ["It is on the bars of %s too."] = "Він є і на панелях: %s.",
    ["It is on the bars of %s."] = "Він є на панелях: %s.",
    ["Specialization %d"] = "Спеціалізація %d",
    ["(full)"] = "(заповнена)",
    ["The %s tab is full."] = "Вкладка «%s» заповнена.",
    ["Makes a copy in this tab with the text from the editor, named like \"Fear 2\". The macro you copy keeps its "
        .. "saved text."] =
        "Робить копію в цій вкладці з текстом із редактора, з назвою на кшталт «Fear 2». Сам макрос лишається таким, "
        .. "яким був збережений.",
    ["Makes a copy for this character only, with the text from the editor, named like \"Fear 2\". The macro you copy "
        .. "keeps its saved text."] =
        "Робить копію лише для цього персонажа з текстом із редактора, з назвою на кшталт «Fear 2». Сам макрос "
        .. "лишається таким, яким був збережений.",
    ["Makes a copy for all your characters, with the text from the editor, named like \"Fear 2\". The macro you copy "
        .. "keeps its saved text."] =
        "Робить копію для всіх ваших персонажів з текстом із редактора, з назвою на кшталт «Fear 2». Сам макрос "
        .. "лишається таким, яким був збережений.",
    ["Makes a copy in this tab, named like \"Fear 2\"."] = "Робить копію в цій вкладці з назвою на кшталт «Fear 2».",
    ["Makes a copy for this character only, named like \"Fear 2\"."] =
        "Робить копію лише для цього персонажа з назвою на кшталт «Fear 2».",
    ["Makes a copy for all your characters, named like \"Fear 2\"."] =
        "Робить копію для всіх ваших персонажів з назвою на кшталт «Fear 2».",
    ["New"] = "Новий",
    ["New (Wizard)"] = "Майстер",
    ["Create a new macro with the built-in wizard! Answer a few simple questions, or fill in the whole form at once: "
        .. "what to cast and on whom (mouseover, focus, party members, yourself, the cursor...), other spells on "
        .. "Shift, Ctrl or Alt, trinkets and more."] =
        "Створіть новий макрос за допомогою вбудованого майстра! Дайте відповідь на кілька простих питань або "
        .. "заповніть одразу всю форму: що застосувати й на кого (маусовер, фокус, члени групи, ви самі, курсор...), "
        .. "інші заклинання на Shift, Ctrl чи Alt, трінкети та інше.",

    -- Main window: share, trash, backups
    ["Share"] = "Обмін",
    ["Share your macros with other players: just pass them the code made for them. Or add someone else's macros "
        .. "to yours, if you have their code."] =
        "Діліться своїми макросами з іншими гравцями: просто передайте їм згенерований код. Або додайте собі "
        .. "чужі макроси, якщо маєте їхній код.",
    ["Export this macro"] = "Експортувати цей макрос",
    ["The code of the saved macro, to copy and share."] = "Код збереженого макроса, щоб скопіювати й поділитися.",
    ["Save the macro first, then export it."] = "Спершу збережіть макрос, потім експортуйте його.",
    ["Export the %s tab (%d)"] = "Експортувати вкладку «%s» (%d)",
    ["The code of every macro in this tab."] = "Код усіх макросів цієї вкладки.",
    ["Export all macros (%d)"] = "Експортувати всі макроси (%d)",
    ["The code of every macro in both tabs. On import, each one goes into its own tab."] =
        "Код усіх макросів з обох вкладок. Під час імпорту кожен потрапить у свою вкладку.",
    ["Import a code or text..."] = "Імпортувати код чи текст...",
    -- links in chat (Links.lua)
    ["Link this macro in chat"] = "Посилання на макрос у чат",
    ["Puts a link to it in the chat. Players with MacroSense can click it to get the macro as it is saved now. "
        .. "Others see only its name. Shift-click on a macro in the list does the same."] =
        "Вставляє в чат посилання на нього. Гравці з MacroSense можуть клацнути його й отримати макрос таким, яким "
        .. "він збережений зараз. Решта побачить лише назву. Shift+клік по макросу в списку робить те саме.",
    ["Save the macro first, then link it."] = "Спершу збережіть макрос, потім вставте посилання.",
    ["Or link a macro in chat. Whoever has MacroSense gets it with one click."] =
        "Або вставте посилання на макрос у чат. Хто має MacroSense, отримає його одним клацанням.",
    ["asking %s for \"%s\"..."] = "питаю в %s макрос «%s»...",
    ["%s no longer shares \"%s\""] = "%s більше не ділиться «%s»",
    ["%s is offline"] = "%s не в мережі",
    ["no answer from %s: they may be offline or not have MacroSense"] =
        "%s не відповідає: можливо, не в мережі або без MacroSense",
    ["addon messages are blocked now (in combat in an instance): try later"] =
        "повідомлення аддонів зараз заблоковані (бій у підземеллі): спробуйте пізніше",
    ["you no longer share \"%s\": link it again"] = "ви більше не ділитеся «%s»: вставте посилання знову",
    ["The macro %s shared in chat. See what is in it, then import it. Nothing gets replaced: if the name is taken, a "
        .. "number is added to it."] =
        "Макрос, яким %s поділився в чаті. Подивіться, що в ньому, і тоді імпортуйте. Нічого не заміниться: якщо "
        .. "назву вже зайнято, до неї додасться номер.",
    ["could not ask %s now: try again in a moment"] = "зараз не вдалося спитати в %s: спробуйте за мить",
    ["Paste a code, or a macro's text from a guide, to add its macros. Nothing gets replaced: if a name is taken, a "
        .. "number is added to it, like \"Fear 2\"."] =
        "Вставте код або текст макроса з гайду, щоб додати його макроси. Нічого не заміниться: якщо назву вже "
        .. "зайнято, до неї додасться номер, як «Fear 2».",
    ["imported %d of %d macros"] = "імпортовано макросів: %d з %d",
    ["Trash"] = "Кошик",
    ["Deleted macros land here, and you can bring them back. It doesn't matter where you deleted them: here, in "
        .. "another addon or in the game's macro window. The trash keeps the last %d deleted macros of each tab and "
        .. "deletes older ones by itself."] =
        "Сюди потрапляють видалені макроси, і їх можна повернути. Неважливо, де ви їх видалили: тут, в іншому аддоні "
        .. "чи в стандартному вікні макросів. Кошик тримає останні %d видалених макросів кожної вкладки, а старіші "
        .. "видаляє сам.",
    ["Deleted from %s: %s. Click to bring it back."] = "Видалено з вкладки «%s»: %s. Клацніть, щоб повернути.",
    ["Delete for good"] = "Видалити назавжди",
    ["No deleted macros"] = "Видалених макросів немає",
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
    ["Restore the backup of %s?\n\nYour macros get back the text and icons they had then, and the missing ones are "
        .. "made again. Macros you made after it stay. First, MacroSense backs up your macros as they are now."] =
        "Відновити бекап (%s)?\n\nМакроси отримають текст та іконки, які мали тоді, а відсутні буде створено знову. "
        .. "Макроси, створені пізніше, лишаться. Спершу MacroSense зробить бекап ваших макросів, якими вони є зараз.",
    ["Delete the backup of %s? It will be gone for good."] = "Видалити бекап (%s)? Він зникне назавжди.",

    -- Main window: editor
    ["Click: choose an icon"] = "Клацання: вибрати іконку",
    ["Drag: put the macro on an action bar"] = "Перетягування: поставити макрос на панель дій",
    ["On your action bars the game shows the question mark for now: as things are right now (keys held, your "
        .. "target, items in your bags), the macro wouldn't use anything. The grey icon only shows what the macro "
        .. "is for."] =
        "Зараз на панелях дій гра показує знак питання: за поточних умов (затиснуті клавіші, ціль, предмети в "
        .. "сумках) макрос нічого не застосує. Сіра іконка лише підказує, для чого макрос.",
    ["Icon chosen by you: it stays the same, even when #showtooltip would change it. To let the game pick it, "
        .. "choose the question mark."] =
        "Іконку вибрали ви: вона не змінюється, навіть коли #showtooltip змінив би її. Щоб гра підбирала її сама, "
        .. "виберіть знак питання.",
    ["click or drag the icon"] = "клацніть або перетягніть іконку",
    ["Shorten"] = "Скоротити",
    ["Shorten -%d"] = "Скоротити -%d",
    ["Makes the macro shorter without changing what it does. It removes spaces the game doesn't need and uses "
        .. "shorter ways to write the same thing. For example, target= becomes @, modifier becomes mod, "
        .. "[pet:Imp][pet:Felhunter] becomes [pet:Imp/Felhunter], and [x] Fear; Fear becomes [x][]Fear."] =
        "Робить макрос коротшим, не змінюючи того, що він робить. Прибирає пробіли, які не потрібні грі, і пише те "
        .. "саме коротше. Наприклад, target= стає @, modifier стає mod, [pet:Imp][pet:Felhunter] стає "
        .. "[pet:Imp/Felhunter], а [x] Fear; Fear стає [x][]Fear.",
    ["%s brings the old text back."] = "%s повертає попередній текст.",
    ["Nothing to shorten here."] = "Тут нічого скорочувати.",
    ["History"] = "Історія",
    ["Earlier saved versions of this macro. Pick one, and it goes into the editor. Save keeps it, and %s takes it "
        .. "back."] =
        "Попередні збережені версії цього макроса. Оберіть версію, і вона з'явиться в редакторі. «Зберегти» її "
        .. "залишить, а %s поверне як було.",
    ["Each time you save a change to this macro, here or in the game's macro window, the text it had before is kept "
        .. "here."] =
        "Щоразу, коли ви зберігаєте зміни цього макроса тут чи в стандартному вікні макросів, попередній текст "
        .. "лишається тут.",
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
    ["Click to go to line %d"] = "Клацніть, щоб перейти до рядка %d",
    ["Click to add \"%s\""] = "Клацніть, щоб додати «%s»",
    ["Click to remove \"%s\""] = "Клацніть, щоб прибрати «%s»",
    ["Discard unsaved changes to this macro?"] = "Відкинути незбережені зміни цього макросу?",
    ["Delete macro \"%s\"?%s"] = "Видалити макрос «%s»?%s",
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
    ["MacroSense: your group's new tank is %s"] = "MacroSense: новий танк групи — %s",
    ["MacroSense: your group's new healer is %s"] = "MacroSense: новий хілер групи — %s",
    ["MacroSense: could not set your group's new tank, %s: the macro would be too long"] =
        "MacroSense: не вдалося призначити нового танка групи — %s: макрос був би задовгим",
    ["MacroSense: could not set your group's new healer, %s: the macro would be too long"] =
        "MacroSense: не вдалося призначити нового хілера групи — %s: макрос був би задовгим",
    ["could not put your group's new names into \"%s\": it would be longer than %d characters"] =
        "не вдалося вписати нові імена вашої групи в «%s»: макрос був би довшим за %d символів",
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
    ["Paste a MacroSense code, or a macro's text from a guide (%s). Nothing gets replaced: if a name is taken, a "
        .. "number is added to it."] =
        "Вставте код MacroSense або текст макроса з гайду (%s). Нічого не заміниться: якщо назву вже зайнято, до неї "
        .. "додасться номер.",
    ["%d macros in the text:"] = { "У тексті %d макрос:", "У тексті %d макроси:", "У тексті %d макросів:" },
    ["This is neither a MacroSense code nor a macro. Each line of a macro starts with / or #."] =
        "Це ні код MacroSense, ні макрос. Кожен рядок макроса починається з / або #.",
    ["The macro's text"] = "Текст макроса",
    ["Press %s to copy the text, then paste it into a guide, a forum or Discord. MacroSense can import it too."] =
        "Натисніть %s, щоб скопіювати текст, і вставте його в гайд, на форум чи в Discord. MacroSense теж уміє його "
        .. "імпортувати.",
    ["Copy this macro's text"] = "Скопіювати текст макроса",
    ["The text of the saved macro, to paste into a guide, a forum or Discord. MacroSense can import it too."] =
        "Текст збереженого макроса, щоб вставити його в гайд, на форум чи в Discord. MacroSense теж уміє його "
        .. "імпортувати.",
    ["Save the macro first, then copy its text."] = "Спершу збережіть макрос, потім скопіюйте його текст.",
    ["MacroSense: %d macros on your bars use spells you don't have now"] = {
        "MacroSense: %d макрос на ваших панелях має заклинання, якого у вас зараз немає",
        "MacroSense: %d макроси на ваших панелях мають заклинання, яких у вас зараз немає",
        "MacroSense: %d макросів на ваших панелях мають заклинання, яких у вас зараз немає",
    },
    ["on your bars, with spells you don't have now: %s"] = "на ваших панелях, із заклинаннями, яких зараз немає: %s",
    ["%d macros in the code:"] = { "У коді %d макрос:", "У коді %d макроси:", "У коді %d макросів:" },
    ["%s: into %s"] = "%s: у «%s»",
    ["%s: into %s as \"%s\" (the name is taken)"] = "%s: у «%s» як «%s» (назву вже зайнято)",
    ["%s: longer than the game allows, not imported"] = "%s: довший, ніж дозволяє гра, не імпортовано",
    ["%s: no free slot in %s"] = "%s: у «%s» немає вільного місця",
    ["... and %d more"] = "... і ще %d",
    ["Import"] = "Імпортувати",
    ["Close"] = "Закрити",
    ["This is not a MacroSense code."] = "Це не код MacroSense.",
    ["The code is cut short or changed. Copy all of it again."] =
        "Код обрізаний або змінений. Скопіюйте його ще раз повністю.",
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
    ["If none of the units above is there, the macro targets the nearest one with this name. Set On to - to target "
        .. "by name only."] =
        "Якщо нікого з обраних вище немає, макрос візьме в ціль найближчого з цим ім'ям. Поставте «-» у полі «На "
        .. "кого», щоб шукати лише за ім'ям.",
    ["Pet"] = "Улюбленець",
    ["On"] = "На кого",
    ["on"] = "на кого",
    ["Then"] = "Далі",
    ["then"] = "далі",
    ["Who the macro casts on. As usual means your target, or you when the game casts on you by itself (Auto Self "
        .. "Cast)."] =
        "На кого макрос застосовує заклинання. «Як завжди» — це ваша ціль або ви самі, коли гра сама застосовує на "
        .. "вас (Auto Self Cast).",
    ["Group's tank and healer are @tank and @heal. The game's macro gets the name of whoever has the role, and "
        .. "MacroSense keeps it up to date."] =
        "«Танк групи» і «Хілер групи» — це @tank і @heal. У макросі гри замість них стоїть ім'я того, хто має цю "
        .. "роль, і MacroSense сам його оновлює.",
    ["If the one before isn't there, or isn't who you need, the macro tries this one."] =
        "Якщо попереднього немає або він не той, хто потрібен, макрос спробує цього.",
    ["Only"] = "Лише",
    ["Anyone there"] = "Будь-хто",
    ["Friends"] = "Друзі",
    ["Enemies"] = "Вороги",
    ["Who the units above must be: friends, enemies or anyone. Yourself, As usual and At the cursor aren't checked. "
        .. "When the game knows who a spell is for, this follows the spell you pick. A key's own spell is checked "
        .. "for who it is for."] =
        "Ким мають бути обрані вище: друзями, ворогами чи будь-ким. «Ви самі», «Як завжди» і «Під курсором» не "
        .. "перевіряються. Коли гра знає, для кого заклинання, це поле саме підлаштується під нього. Власне "
        .. "заклинання клавіші перевіряється за тим, для кого воно.",
    ["Alive only"] = "Лише живі",
    ["With a key held"] = "З клавішею",
    ["same spell"] = "те саме заклинання",
    ["macOS uses some keys with Cmd itself: Q quits the game, and W, H, Tab, Space and others do things too. On "
        .. "those keys macOS acts first, so the editor warns you when the macro is on one."] =
        "Деякі клавіші з Cmd macOS використовує сама: Q закриває гру, а W, H, Tab, Space та інші теж щось роблять. "
        .. "На таких клавішах першою спрацьовує macOS, тож редактор попередить, якщо макрос стоїть на одній із них.",
    ["Start over"] = "Почати знову",
    ["New target"] = "Нова ціль",
    ["Combat ends"] = "Кінець бою",
    ["What makes the sequence start again from its first spell: a new target, the end of combat, a press with Shift, "
        .. "Ctrl or Alt held, or a few seconds without a press."] =
        "Що змушує послідовність почати знову з першого заклинання: нова ціль, кінець бою, натискання із затиснутим "
        .. "Shift, Ctrl чи Alt або кілька секунд без натискань.",
    ["After"] = "Через",
    ["seconds without a press"] = "с без натискань",
    ["Also"] = "Ще",
    ["Stop your cast first"] = "Спершу перервати каст",
    ["For an interrupt or a save: it goes off at once, even in the middle of another cast."] =
        "Для переривання чи порятунку: спрацює одразу, навіть посеред іншого заклинання.",
    ["Trinket 1"] = "Трінкет 1",
    ["Trinket 2"] = "Трінкет 2",
    ["Trinket %d: %s"] = "Трінкет %d: %s",
    ["empty"] = "порожньо",
    ["Your trinkets go off first (/use 13, /use 14), whenever they are ready."] =
        "Спершу спрацьовують ваші трінкети (/use 13, /use 14), коли вони готові.",
    ["Nearest enemy if none"] = "Найближчий ворог",
    ["If your target isn't an enemy or is dead, the macro first targets the nearest enemy (/targetenemy "
        .. "[noharm][dead])."] =
        "Якщо ваша ціль не ворог або мертва, макрос спершу візьме в ціль найближчого ворога (/targetenemy "
        .. "[noharm][dead]).",
    ["Start auto attack"] = "Автоатака",
    ["Leave your form first"] = "Спершу вийти з форми",
    ["Leaves your form or stance first (/cancelform). For example, to heal while you are in Bear Form."] =
        "Спершу виходить із форми чи стійки (/cancelform). Наприклад, щоб полікувати, коли ви у формі ведмедя.",
    ["Pet attacks your target"] = "Улюбленець атакує ціль",
    ["Off your mount first"] = "Спершу злізти з маунта",
    ["Gets you off your mount first (/dismount [mounted]), so the spell doesn't fail."] =
        "Спершу знімає вас із маунта (/dismount [mounted]), щоб заклинання не зірвалося.",
    ["Cancel a buff"] = "Скасувати бафф",
    ["Cancel a buff first"] = "Спершу скасувати бафф",
    ["the buff's name"] = "назва баффу",
    ["Removes this buff before anything else (/cancelaura Ice Block). Leave it empty to keep your buffs. The list "
        .. "shows the buffs you have now and the ones you had before."] =
        "Знімає цей бафф перед усім іншим (/cancelaura Ice Block). Залиште порожнім, щоб нічого не знімати. У списку "
        .. "є баффи, які на вас зараз і які були раніше.",
    ["Say in chat"] = "Сказати в чат",
    ["The macro says this after everything else, in the channel on the left. %t is your target's name. Leave it "
        .. "empty to say nothing."] =
        "Макрос напише це після всього іншого, у канал ліворуч. %t — ім'я вашої цілі. Залиште порожнім, щоб нічого "
        .. "не писати.",
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
        "Зілля, камінь здоров'я, іграшку... або трінкет, який на вас.",
    ["Several spells in turn"] = "Кілька заклинань по черзі",
    ["Each press casts the next spell of the list: the first press the first spell, the next press the second, and "
        .. "so on."] =
        "Кожне натискання застосовує наступне заклинання зі списку: перше натискання — перше, наступне — друге і "
        .. "так далі.",
    ["One of several at random"] = "Одне з кількох навмання",
    ["Each press casts one of the spells at random. For example, a random mount."] =
        "Кожне натискання застосовує одне із заклинань навмання. Наприклад, випадковий маунт.",
    ["Target someone"] = "Взяти когось у ціль",
    ["Set your focus"] = "Задати фокус",
    ["Your focus is a second target you keep an eye on. For example, to interrupt it or keep it crowd controlled "
        .. "while you fight another."] =
        "Фокус — це друга ціль, за якою ви стежите. Наприклад, щоб перебивати її касти чи тримати під контролем, "
        .. "поки б'єтеся з іншою.",
    ["Take someone's target"] = "Взяти чужу ціль",
    ["You take the same target as someone else, such as the tank."] =
        "Ви берете ту саму ціль, що й хтось інший, наприклад танк.",
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
    ["Pick any of these, or none. With none, it starts again only after the last spell."] =
        "Оберіть будь-що з цього або нічого. Якщо нічого, вона почнеться знову лише після останнього заклинання.",
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
    ["On your group's tank"] = "На танка вашої групи",
    ["On your group's healer"] = "На хілера вашої групи",
    ["On party member %d"] = "На члена групи %d",
    ["On arena enemy %d"] = "На ворога на арені %d",
    ["Your target, as usual"] = "Ваша ціль, як завжди",
    ["Your target, if a friend"] = "Ваша ціль, якщо це друг",
    ["Your target, if an enemy"] = "Ваша ціль, якщо це ворог",
    ["Your target, if there is one"] = "Ваша ціль, якщо вона є",
    ["Whoever is under the mouse"] = "Той, хто під мишею",
    ["Your focus"] = "Ваш фокус",
    ["Your target's target"] = "Ціль вашої цілі",
    ["Your group's tank"] = "Танк вашої групи",
    ["Your group's healer"] = "Хілер вашої групи",
    ["Party member %d"] = "Член групи %d",
    ["Arena enemy %d"] = "Ворог на арені %d",
    ["Do nothing"] = "Нічого не робити",
    ["Someone by name"] = "Хтось за ім'ям",
    ["The game decides: your target, or you when the game casts on you by itself (Auto Self Cast)."] =
        "Як вирішить гра: ваша ціль або ви самі, коли гра сама застосовує на вас (Auto Self Cast).",
    ["The one your mouse points at, in the world or on a frame (party, raid). Your target stays as it is."] =
        "Той, на кого вказує миша, у світі чи на рамці (група, рейд). Ваша ціль при цьому не змінюється.",
    ["For spells you cast on the ground, like Blizzard. The spell lands under the cursor at once, with no circle to "
        .. "place."] =
        "Для заклинань на землю, як-от Blizzard. Заклинання одразу падає під курсор, коло ставити не треба.",
    ["A second target you keep an eye on. /focus sets it."] = "Друга ціль, за якою ви стежите. Її задає /focus.",
    ["Whoever your target is targeting, such as the one a boss attacks."] =
        "Той, кого взяла в ціль ваша ціль, наприклад той, кого б'є бос.",
    ["Your party members, as your party frames list them from the top."] =
        "Члени вашої групи в тому порядку, як їх показують рамки групи згори.",
    ["The one with the tank role in your party or raid, other than you."] =
        "Той, хто має роль танка у вашій групі чи рейді, окрім вас.",
    ["The one with the healer role in your party or raid, other than you."] =
        "Той, хто має роль хілера у вашій групі чи рейді, окрім вас.",
    ["MacroSense puts in the name of the one with the role now, and a new one when your group changes (out of "
        .. "combat)."] =
        "MacroSense вписує в макрос ім'я того, хто має цю роль зараз, а коли група зміниться — нове (поза боєм).",
    ["The enemies of an arena match, in the order of their frames."] = "Вороги на арені в порядку їхніх рамок.",
    ["And if nobody is under the mouse?"] = "А якщо під мишею нікого немає?",
    ["And if you have no target?"] = "А якщо у вас немає цілі?",
    ["And if you have no focus?"] = "А якщо у вас немає фокуса?",
    ["And if your pet is not out?"] = "А якщо улюбленця немає поруч?",
    ["And if your target has no target?"] = "А якщо у вашої цілі немає цілі?",
    ["And if your group has no tank?"] = "А якщо у вашій групі немає танка?",
    ["And if your group has no healer?"] = "А якщо у вашій групі немає хілера?",
    ["And if party member %d is not there?"] = "А якщо члена групи %d немає?",
    ["And if arena enemy %d is not there?"] = "А якщо ворога на арені %d немає?",
    ["Or the one there is not a friend, or is dead."] = "Або той, хто там є, не друг чи мертвий.",
    ["Or the one there is not a friend."] = "Або той, хто там є, не друг.",
    ["Or the one there is not an enemy, or is dead."] = "Або той, хто там є, не ворог чи мертвий.",
    ["Or the one there is not an enemy."] = "Або той, хто там є, не ворог.",
    ["Or the one there is dead."] = "Або той, хто там є, мертвий.",
    ["What name should it look for?"] = "Яке ім'я шукати?",
    ["The nearest one with this name becomes your target, such as a rare."] =
        "Вашою ціллю стане найближчий з таким ім'ям, наприклад рідкісний монстр.",
    ["Should the macro do something else while you hold %s?"] =
        "Чи має макрос робити щось інше, поки ви тримаєте %s?",
    ["Pick the keys you want, or none. For each key, the next questions ask what it does."] =
        "Оберіть потрібні клавіші або жодної. Для кожної далі буде питання, що вона робить.",
    ["With %s held"] = "Із затиснутим %s",
    ["Would you like to add anything else?"] = "Бажаєте додати ще щось?",
    ["Pick any of these, or none."] = "Оберіть що завгодно з цього або нічого.",
    ["Which rank of %s?"] = "Який ранг «%s»?",
    ["The highest you know"] = "Найвищий, який ви знаєте",
    ["Usually the highest you know. It updates by itself when you learn a new one."] =
        "Зазвичай найвищий, який ви знаєте. Коли вивчите новий, він оновиться сам.",
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
    ["Group's tank"] = "Танк групи",
    ["Group's healer"] = "Хілер групи",
    ["Arena enemy 1"] = "Ворог на арені 1",
    ["Arena enemy 2"] = "Ворог на арені 2",
    ["Arena enemy 3"] = "Ворог на арені 3",
    ["At the cursor"] = "Під курсором",
    ["Clear focus"] = "Зняти фокус",
    ["Clear target"] = "Зняти ціль",
    -- the names the wizard gives a macro that casts nothing of its own
    ["Target"] = "Ціль",
    ["Assist"] = "Допомога",
    ["Trinkets"] = "Трінкети",
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
    -- what a line does, in plain words (Explain.lua)
    ["Line %d"] = "Рядок %d",
    ["Point at a line's number or its note to read what the whole line does, in plain words."] =
        "Наведіть мишу на номер рядка чи його нотатку, щоб прочитати простими словами, що робить увесь рядок.",
    ["%s: %s"] = "%s: %s",
    ["otherwise: %s"] = "інакше: %s",
    ["otherwise, %s: %s"] = "інакше, %s: %s",
    ["if not, %s"] = "якщо ні — %s",
    ["%s on %s"] = "%s на %s",
    ["on %s"] = "на %s",
    ["%s at the cursor"] = "%s у місце під курсором",
    ["at the cursor"] = "у місце під курсором",
    ["if it is %s"] = "якщо він %s",
    [" and "] = " і ",
    [" or "] = " або ",
    ["if there is one"] = "якщо він є",
    ["if there is none"] = "якщо його немає",
    ["the item in %s"] = "предмет зі слоту «%s»",
    ["%s in turn, one each press"] = "%s по черзі, по одному за натискання",
    ["starting over %s"] = "починаючи спочатку %s",
    ["on a new target"] = "з новою ціллю",
    ["when combat ends"] = "коли бій закінчиться",
    ["after %s seconds without a press"] = "через %s с без натискань",
    ["one of %s at random"] = "навмання одне з: %s",
    ["equips %s"] = "вдягає %s",
    ["equips %s in %s"] = "вдягає %s у слот «%s»",
    ["cancels %s"] = "скасовує %s",
    ["the macro stops here"] = "макрос зупиняється тут",
    ["clicks %s"] = "натискає %s",
    ["runs Lua code"] = "виконує код Lua",
    ["writes in chat: %s"] = "пише в чат: %s",
    ["runs /%s"] = "виконує /%s",
    ["shows the icon and tooltip of %s"] = "показує іконку й підказку %s",
    ["shows the icon of %s"] = "показує іконку %s",
    ["the spell or item the macro uses"] = "того, що використовує макрос",
    ["targets %s"] = "бере в ціль %s",
    ["sets %s as your focus"] = "робить фокусом %s",
    ["takes the target of %s"] = "бере ціль (асист): %s",
    ["clears your focus"] = "прибирає фокус",
    ["clears your target"] = "прибирає ціль",
    ["starts auto attack"] = "починає автоатаку",
    ["starts auto attack on %s"] = "починає автоатаку на %s",
    ["stops auto attack"] = "зупиняє автоатаку",
    ["stops your cast"] = "перериває ваше заклинання",
    ["cancels the spell waiting for its target"] = "скасовує заклинання, що чекає на ціль",
    ["leaves your form"] = "виходить із форми",
    ["gets off your mount"] = "злазить з маунта",
    ["your pet attacks %s"] = "ваш улюбленець атакує %s",
    ["your pet follows you"] = "ваш улюбленець іде за вами",
    ["your pet stays where it is"] = "ваш улюбленець лишається на місці",
    ["your pet goes to the cursor"] = "ваш улюбленець іде туди, де курсор",
    ["your pet goes where you click"] = "ваш улюбленець іде туди, куди ви клацнете",
    ["your pet turns passive"] = "ваш улюбленець стає пасивним",
    ["your pet turns defensive"] = "ваш улюбленець стає захисним",
    ["your pet turns aggressive"] = "ваш улюбленець стає агресивним",
    ["your pet turns to assist"] = "ваш улюбленець переходить у режим допомоги",
    ["dismisses your pet"] = "відпускає улюбленця",
    ["turns autocast of %s on"] = "вмикає автозастосування %s",
    ["turns autocast of %s off"] = "вимикає автозастосування %s",
    ["turns autocast of %s on or off"] = "перемикає автозастосування %s",
    ["puts on the equipment set %s"] = "вдягає комплект %s",
    ["targets the nearest enemy"] = "бере в ціль найближчого ворога",
    ["targets the nearest friend"] = "бере в ціль найближчого друга",
    ["targets your last target"] = "бере в ціль вашу попередню ціль",
    ["targets the nearest party member"] = "бере в ціль найближчого члена групи",
    ["targets the nearest raid member"] = "бере в ціль найближчого члена рейду",
    ["switches to action bar page %s"] = "перемикає на сторінку панелі дій %s",
    -- units, after "on" (the accusative)
    ["your target"] = "вашу ціль",
    ["your focus"] = "ваш фокус",
    ["the unit under the mouse"] = "того, хто під мишею",
    ["yourself"] = "себе",
    ["your pet"] = "вашого улюбленця",
    ["your vehicle"] = "ваш транспорт",
    ["your target's target"] = "ціль вашої цілі",
    ["whoever you click"] = "того, на кого ви клацнете",
    ["your group's tank"] = "танка вашої групи",
    ["your group's healer"] = "хілера вашої групи",
    ["the one you are talking to"] = "того, з ким ви говорите",
    ["party member %d"] = "члена групи %d",
    ["the pet of party member %d"] = "улюбленця члена групи %d",
    ["raid member %d"] = "члена рейду %d",
    ["the pet of raid member %d"] = "улюбленця члена рейду %d",
    ["arena enemy %d"] = "ворога арени %d",
    ["the pet of arena enemy %d"] = "улюбленця ворога арени %d",
    ["boss %d"] = "боса %d",
    ["the target of %s"] = "ціль (%s)",
    -- about the unit: "if it is ..."
    ["a friend"] = "друг",
    ["not a friend"] = "не друг",
    ["an enemy"] = "ворог",
    ["not an enemy"] = "не ворог",
    ["dead"] = "мертвий",
    ["alive"] = "живий",
    ["in your party"] = "у вашій групі",
    ["not in your party"] = "не у вашій групі",
    ["in your raid"] = "у вашому рейді",
    ["not in your raid"] = "не у вашому рейді",
    ["not in a vehicle"] = "не в транспорті",
    -- about you and the game
    ["in stealth"] = "у стелсі",
    ["out of stealth"] = "не в стелсі",
    ["mounted"] = "верхи",
    ["not mounted"] = "не верхи",
    ["not flying"] = "не в польоті",
    ["where you can fly"] = "там, де можна літати",
    ["where you can't fly"] = "там, де літати не можна",
    ["where you can skyride"] = "там, де працює небесна їзда",
    ["where you can't skyride"] = "там, де небесна їзда не працює",
    ["not swimming"] = "не у воді",
    ["not indoors"] = "не в приміщенні",
    ["not outdoors"] = "не надворі",
    ["resting, in a city or an inn"] = "на відпочинку, у місті чи таверні",
    ["not resting"] = "не на відпочинку",
    ["with something on the cursor"] = "коли щось на курсорі",
    ["with nothing on the cursor"] = "коли на курсорі нічого",
    ["not in a pet battle"] = "не в битві улюбленців",
    ["when you can leave the vehicle"] = "коли можна вийти з транспорту",
    ["when you can't leave the vehicle"] = "коли вийти з транспорту не можна",
    ["while you control another creature"] = "коли ви керуєте іншою істотою",
    ["while you control no other creature"] = "коли ви не керуєте іншою істотою",
    ["with a special action bar"] = "з особливою панеллю дій",
    ["without a special action bar"] = "без особливої панелі дій",
    ["with the extra action button"] = "з додатковою кнопкою дії",
    ["without the extra action button"] = "без додаткової кнопки дії",
    ["shapeshifted"] = "у зміненій подобі",
    ["not shapeshifted"] = "не в зміненій подобі",
    ["with a bonus action bar"] = "з бонусною панеллю дій",
    ["without a bonus action bar"] = "без бонусної панелі дій",
    ["with bonus action bar %s"] = "з бонусною панеллю дій %s",
    ["without bonus action bar %s"] = "без бонусної панелі дій %s",
    ["while channeling"] = "під час потокового заклинання",
    ["not channeling"] = "не під час потокового заклинання",
    ["while channeling %s"] = "під час %s",
    ["not channeling %s"] = "не під час %s",
    ["with your pet out"] = "коли ваш улюбленець поруч",
    ["with no pet out"] = "без улюбленця",
    ["with %s out"] = "коли поруч %s",
    ["without %s out"] = "коли %s не поруч",
    ["with %s equipped"] = "з вдягнутим %s",
    ["without %s equipped"] = "без вдягнутого %s",
    ["if you know %s"] = "якщо ви знаєте %s",
    ["if you don't know %s"] = "якщо ви не знаєте %s",
    ["with the PvP talent %s"] = "з PvP-талантом %s",
    ["without the PvP talent %s"] = "без PvP-таланту %s",
    ["on action bar page %s"] = "на сторінці панелі дій %s",
    ["not on action bar page %s"] = "не на сторінці панелі дій %s",
    ["in specialization %s"] = "у спеціалізації %s",
    ["not in specialization %s"] = "не в спеціалізації %s",
    ["in a form"] = "у формі",
    ["in no form"] = "без форми",
    ["in %s"] = "у %s",
    ["not in %s"] = "не в %s",
    ["form %s"] = "форма %s",
    ["with the talent of %s"] = "з талантом: %s",
    ["without the talent of %s"] = "без таланту: %s",
    ["row %s, column %s"] = "ряд %s, стовпець %s",
    ["clicked with %s"] = "натиснуто %s",
    ["not clicked with %s"] = "натиснуто не %s",
    ["the left mouse button"] = "лівою кнопкою миші",
    ["the right mouse button"] = "правою кнопкою миші",
    ["the middle mouse button"] = "середньою кнопкою миші",
    ["mouse button %s"] = "кнопкою миші %s",
    ["with %s held"] = "із затиснутим %s",
    ["without %s held"] = "без затиснутого %s",
    ["with no key held"] = "без затиснутих клавіш",
    ["with Shift, Ctrl or Alt held"] = "із затиснутим Shift, Ctrl чи Alt",
    ["left %s"] = "%s (лівий)",
    ["right %s"] = "%s (правий)",
    ["not in a group"] = "не в групі",
    ["in a raid"] = "у рейді",
    ["not in a raid"] = "не в рейді",

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
    ["stealthed"] = "у стелсі",
    ["on a mount"] = "на маунті",
    ["flying"] = "у польоті",
    ["flying allowed"] = "можна літати",
    ["skyriding allowed"] = "можна skyriding",
    ["swimming"] = "у воді",
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
    ["in a pet battle"] = "у битві улюбленців",
    ["holding something on cursor"] = "щось на курсорі",
    ["nothing on cursor"] = "на курсорі нічого",
    ["unit is not hostile"] = "не ворожий",
    ["unit is not friendly"] = "не дружній",
    ["unit in your party"] = "у вашій групі",
    ["unit not in your party"] = "не у вашій групі",
    ["unit in your raid"] = "у вашому рейді",
    ["unit not in your raid"] = "не у вашому рейді",
    ["not stealthed"] = "не в стелсі",
    ["not on a mount"] = "не на маунті",
    ["flying not allowed"] = "літати не можна",
    ["skyriding not allowed"] = "skyriding не можна",
    ["not in a rested area"] = "не в зоні відпочинку",
    ["another specialization"] = "інша спеціалізація",
    ["spell is not known"] = "заклинання не відоме",
    ["pvp talent not chosen"] = "PvP-талант не вибрано",
    ["item type not equipped"] = "не вдягнено тип предмета",
    ["another mouse button"] = "інша кнопка миші",
    ["another action bar page"] = "інша сторінка панелі дій",
    ["no bonus bar"] = "без бонусної панелі",
    ["no extra action bar"] = "без додаткової кнопки дії",
    ["no override bar"] = "без панелі заміни",
    ["no possess bar"] = "без панелі контролю",
    ["unit not in a vehicle"] = "ціль не в транспорті",
    ["can't leave vehicle"] = "не можна вийти з транспорту",
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
    ["group's tank"] = "танк групи",
    ["group's healer"] = "хілер групи",
    ["NPC you talk to"] = "NPC, з яким ви говорите",
    ["highest"] = "найвищий",
    ["equipped"] = "вдягнено",
    ["item"] = "предмет",
    ["primary"] = "основна",
    ["secondary"] = "додаткова",
    ["your pet's name"] = "ім'я вашого улюбленця",
    ["pet family"] = "родина улюбленця",
    ["extra action"] = "додаткова дія",
    ["popup: first button"] = "вікно: перша кнопка",
    ["popup: second button"] = "вікно: друга кнопка",
    ["on you now"] = "зараз на вас",
    ["buff"] = "бафф",
    -- Docs.lua: what a word of a macro means
    ["Casts a spell or uses an item by its name. Branches split by \";\" are tried in order: the first whose "
        .. "conditions hold runs."] =
        "Застосовує заклинання або предмет за назвою. Гілки, розділені «;», перевіряються по черзі: спрацьовує "
        .. "перша, умови якої виконано.",
    ["Uses an item: by name, item:ID, an equipment slot (13, 14 for trinkets) or a bag and slot (0 1). Spells work "
        .. "too, as with /cast."] =
        "Використовує предмет: за назвою, item:ID, слотом спорядження (13, 14 — трінкети) або сумкою й слотом (0 1). "
        .. "Заклинання теж працюють, як із /cast.",
    ["Casts the next spell of the list on each press. reset= says when it starts over: after seconds "
        .. "without a press, a new target, the end of combat, or Shift, Ctrl, Alt held."] =
        "Щоразу застосовує наступне заклинання зі списку. reset= каже, коли почати спочатку: через стільки-то "
        .. "секунд без натискань, на нову ціль, після бою або з затиснутим Shift, Ctrl, Alt.",
    ["Casts one spell of the list, picked at random."] = "Застосовує одне заклинання зі списку навмання.",
    ["Uses one item of the list, picked at random (mounts, toys)."] =
        "Використовує один предмет зі списку навмання (маунти, іграшки).",
    ["Stops the spell you are casting, so the line after it can cast at once."] =
        "Перериває заклинання, яке ви зараз застосовуєте, щоб наступний рядок спрацював одразу.",
    ["Stops the macro here when its conditions hold: the lines below it don't run."] =
        "Зупиняє макрос тут, якщо умови виконано: рядки нижче не виконуються.",
    ["Starts auto attack on your target, or on the unit given. It never turns auto attack off."] =
        "Вмикає автоатаку по вашій цілі або по вказаному юніту. Вимкнути автоатаку вона не може.",
    ["Stops auto attack."] = "Вимикає автоатаку.",
    ["Removes a buff from you, by its name."] = "Знімає з вас бафф за його назвою.",
    ["Leaves your form or stance (Bear Form, Shadowform...)."] =
        "Виходить із форми чи стійки (Bear Form, Shadowform...).",
    ["Targets a unit, or the nearest player or creature with that name."] =
        "Бере в ціль юніта або найближчого гравця чи істоту з таким ім'ям.",
    ["Targets the next enemy in front of you, as Tab does."] = "Бере в ціль наступного ворога перед вами, як Tab.",
    ["Targets the next friendly player."] = "Бере в ціль наступного дружнього гравця.",
    ["Targets your previous target again."] = "Знову бере в ціль попередню ціль.",
    ["Clears your target."] = "Скидає вашу ціль.",
    ["Targets the target of a unit: /assist [@focus] takes your focus's target."] =
        "Бере в ціль ціль юніта: /assist [@focus] бере ціль вашого фокуса.",
    ["Sets your focus: the unit given, or your target. A focus stays while you target others."] =
        "Ставить фокус: на вказаного юніта або на вашу ціль. Фокус лишається, поки ви берете в ціль інших.",
    ["Clears your focus."] = "Скидає фокус.",
    ["Your pet attacks your target, or the unit given."] = "Ваш улюбленець атакує вашу ціль або вказаного юніта.",
    ["Your pet comes back and follows you."] = "Ваш улюбленець повертається й іде за вами.",
    ["Your pet stays where it is."] = "Ваш улюбленець лишається на місці.",
    ["Your pet doesn't attack by itself."] = "Ваш улюбленець сам не атакує.",
    ["Your pet attacks what attacks you or it."] = "Ваш улюбленець атакує тих, хто атакує вас або його.",
    ["Your pet attacks what you attack."] = "Ваш улюбленець атакує те, що атакуєте ви.",
    ["Puts on an item from your bags, in the slot it goes to."] = "Вдягає предмет із сумок у його слот.",
    ["Puts on an item in the slot given: /equipslot 14 Name for the second trinket."] =
        "Вдягає предмет у вказаний слот: /equipslot 14 Назва — це другий трінкет.",
    ["Clicks a button by its frame name, as if you pressed it: /click ActionButton1."] =
        "Натискає кнопку за назвою її фрейму, ніби ви натиснули її самі: /click ActionButton1.",
    ["Gets you off your mount."] = "Злазить із маунта.",
    ["Leaves the vehicle you are in."] = "Виходить із транспорту.",
    ["Runs a line of Lua code. Addons' code can't cast spells, so this can't either."] =
        "Виконує рядок коду Lua. Код аддонів не може застосовувати заклинання, тож і він не може.",
    ["Says the text in chat, to players near you. %t is your target's name."] =
        "Каже текст у чат гравцям поруч. %t — ім'я вашої цілі.",
    ["Yells the text in chat, to players in a wide area. %t is your target's name."] =
        "Кричить текст у чат гравцям на великій відстані. %t — ім'я вашої цілі.",
    ["Says the text in your party's chat. %t is your target's name."] = "Пише текст у чат групи. %t — ім'я вашої цілі.",
    ["Says the text in your raid's chat. %t is your target's name."] = "Пише текст у чат рейду. %t — ім'я вашої цілі.",
    ["Shows the text as your emote: \"Bob waves.\" %t is your target's name."] =
        "Показує текст як вашу емоцію: «Bob махає рукою.» %t — ім'я вашої цілі.",
    ["Whispers the text to one player: /whisper Name text."] = "Шепоче текст одному гравцю: /whisper Ім'я текст.",
    ["You are in combat."] = "Ви в бою.",
    ["A modifier key is held: mod:shift, mod:ctrl, mod:alt, several with \"/\". Without a value, any of them."] =
        "Затиснуто клавішу-модифікатор: mod:shift, mod:ctrl, mod:alt, кілька через «/». Без значення — будь-яку.",
    ["The unit is an enemy you can attack."] = "Юніт — ворог, якого можна атакувати.",
    ["The unit is friendly: you can heal or buff it."] = "Юніт дружній: його можна лікувати чи баффати.",
    ["The unit is there. With nobody under the mouse, @mouseover is not."] =
        "Юніт є. Коли під мишею нікого, @mouseover немає.",
    ["The unit is dead."] = "Юніт мертвий.",
    ["Your form or stance, by its number: form:1, form:2/3. form:0 or noform: no form."] =
        "Ваша форма чи стійка за номером: form:1, form:2/3. form:0 або noform — без форми.",
    ["You are in stealth."] = "Ви в стелсі.",
    ["You are on a mount."] = "Ви на маунті.",
    ["You are flying."] = "Ви летите.",
    ["You can fly here: the zone allows it."] = "Тут можна літати: зона це дозволяє.",
    ["Skyriding is allowed here."] = "Тут дозволено skyriding.",
    ["You are swimming."] = "Ви у воді.",
    ["You are indoors, where mounts can't be summoned."] = "Ви в приміщенні, де маунта не викликати.",
    ["You are outdoors."] = "Ви надворі.",
    ["You are in a rested area: an inn or a city."] = "Ви в зоні відпочинку: у таверні чи місті.",
    ["You are channeling a spell, any or the one named: channeling:Drain Life."] =
        "Ви зараз застосовуєте потокове заклинання, будь-яке або назване: channeling:Drain Life.",
    ["You are in a group: group:party or group:raid."] = "Ви в групі: group:party або group:raid.",
    ["The unit is in your party."] = "Юніт у вашій групі.",
    ["The unit is in your raid."] = "Юніт у вашому рейді.",
    ["Your pet is out, or that one: pet:Felhunter, pet:Imp/Voidwalker."] =
        "Ваш улюбленець викликаний, або саме цей: pet:Felhunter, pet:Imp/Voidwalker.",
    ["Your active specialization: spec:1, spec:2..."] = "Ваша активна спеціалізація: spec:1, spec:2...",
    ["You know that spell: known:Name or its number."] = "Ви знаєте це заклинання: known:Назва або його номер.",
    ["That talent is chosen: talent:row/column."] = "Цей талант обрано: talent:ряд/стовпець.",
    ["That PvP talent is chosen."] = "Цей PvP-талант обрано.",
    ["You wear that kind of item: equipped:Shields, equipped:Two-Handed Axes."] =
        "На вас такий тип предмета: equipped:Shields, equipped:Two-Handed Axes.",
    ["The mouse button that clicked the action button: btn:1 left, btn:2 right."] =
        "Кнопка миші, якою клацнули по кнопці дії: btn:1 — ліва, btn:2 — права.",
    ["The page of your action bar now: bar:2."] = "Поточна сторінка панелі дій: bar:2.",
    ["A bonus bar is up (forms and stances change it): bonusbar:1."] =
        "Увімкнено бонусну панель (її міняють форми й стійки): bonusbar:1.",
    ["The extra action button is shown."] = "Показано додаткову кнопку дії.",
    ["An override bar replaces your action bar."] = "Вашу панель дій замінює інша панель.",
    ["You control another creature's actions."] = "Ви керуєте діями іншої істоти.",
    ["You are in a vehicle with its own action bar."] = "Ви в транспорті з власною панеллю дій.",
    ["The unit is in a vehicle."] = "Юніт у транспорті.",
    ["You can leave the vehicle you are in."] = "Ви можете вийти з транспорту.",
    ["You are in a pet battle."] = "Ви в бою улюбленців.",
    ["You hold something on the mouse cursor: a spell, an item, a macro."] =
        "Ви тримаєте щось на курсорі миші: заклинання, предмет, макрос.",
    ["The one you have targeted."] = "Той, кого ви взяли в ціль.",
    ["A unit you set with /focus: you act on it without targeting it."] =
        "Юніт, якого ви поставили в /focus: на нього можна діяти, не беручи в ціль.",
    ["The unit under the mouse: in the world, on its nameplate or on a unit frame."] =
        "Юніт під мишею: у світі, на його неймплейті або на рамці юніта.",
    ["You."] = "Ви.",
    ["The ground under the mouse: a spell you aim lands there at once, without a click."] =
        "Земля під мишею: заклинання, яке треба націлювати, падає туди одразу, без кліку.",
    ["Nobody: a spell that needs a target asks you to click one."] =
        "Ніхто: заклинання, якому потрібна ціль, попросить клацнути по ній.",
    ["Your group's tank, other than you. MacroSense puts in the name of the one with the role, and a new one "
        .. "when your group changes."] =
        "Танк вашої групи, окрім вас. MacroSense вписує ім'я того, хто має цю роль, і нове, коли група змінюється.",
    ["Your group's healer, other than you. MacroSense puts in the name of the one with the role, and a new "
        .. "one when your group changes."] =
        "Хілер вашої групи, окрім вас. MacroSense вписує ім'я того, хто має цю роль, і нове, коли група змінюється.",
    ["Your target if it is an enemy, else the enemy your soft targeting picks."] =
        "Ваша ціль, якщо це ворог, інакше ворог, якого обирає м'яке націлювання.",
    ["Your target if it is friendly, else the friend your soft targeting picks."] =
        "Ваша ціль, якщо вона дружня, інакше друг, якого обирає м'яке націлювання.",
    ["The enemy your soft targeting picks: the one in front of you."] =
        "Ворог, якого обирає м'яке націлювання: той, що перед вами.",
    ["The friend your soft targeting picks."] = "Друг, якого обирає м'яке націлювання.",
    ["What your soft targeting picks to interact with."] = "Те, з чим м'яке націлювання пропонує взаємодіяти.",
    ["Your target if you can interact with it, else what soft targeting picks."] =
        "Ваша ціль, якщо з нею можна взаємодіяти, інакше те, що обирає м'яке націлювання.",
    ["The unit of a nameplate shown, by its number."] = "Юніт показаного неймплейта, за номером.",
    ["The macro's icon and tooltip are of the spell or item it would use now: of the first line that "
        .. "casts, or of the one named after it."] =
        "Іконка й підказка макроса — від заклинання чи предмета, які він застосував би зараз: першого рядка, що "
        .. "кастує, або названого після нього.",
    ["The macro's icon is of the spell or item it would use now, with no tooltip."] =
        "Іконка макроса — від заклинання чи предмета, які він застосував би зараз, без підказки.",
    ["On whom the branch acts: @mouseover, @focus, @player... target= is the same."] =
        "На кого діє гілка: @mouseover, @focus, @player... target= — те саме.",
    ["You are not in combat."] = "Ви не в бою.",
    ["No modifier key is held: nomod:shift, no Shift. Without a value, none of them."] =
        "Не затиснуто клавішу-модифікатор: nomod:shift — не затиснуто Shift. Без значення — жодної.",
    ["The unit is not an enemy you can attack."] = "Юніт — не ворог, якого можна атакувати.",
    ["The unit is not friendly."] = "Юніт не дружній.",
    ["The unit is not there. For example, nobody is under the mouse."] = "Юніта немає. Наприклад, під мишею нікого.",
    ["The unit is not dead."] = "Юніт не мертвий.",
    ["You are not in that form or stance: noform, in none."] = "Ви не в цій формі чи стійці: noform — у жодній.",
    ["You are not in stealth."] = "Ви не в стелсі.",
    ["You are not on a mount."] = "Ви не на маунті.",
    ["You are not flying."] = "Ви не летите.",
    ["You can't fly here."] = "Тут не можна літати.",
    ["Skyriding is not allowed here."] = "Тут не дозволено skyriding.",
    ["You are not swimming."] = "Ви не у воді.",
    ["You are not indoors."] = "Ви не в приміщенні.",
    ["You are not outdoors."] = "Ви не надворі.",
    ["You are not in a rested area."] = "Ви не в зоні відпочинку.",
    ["You are not channeling a spell, or not that one."] = "Ви не застосовуєте потокове заклинання, або не це.",
    ["You are not in a group, or not in that kind."] = "Ви не в групі, або не в такій.",
    ["The unit is not in your party."] = "Юніт не у вашій групі.",
    ["The unit is not in your raid."] = "Юніт не у вашому рейді.",
    ["Your pet is not out, or not that one."] = "Ваш улюбленець не викликаний, або не цей.",
    ["That specialization is not active."] = "Ця спеціалізація не активна.",
    ["You don't know that spell."] = "Ви не знаєте цього заклинання.",
    ["That talent is not chosen."] = "Цей талант не обрано.",
    ["That PvP talent is not chosen."] = "Цей PvP-талант не обрано.",
    ["You don't wear that kind of item."] = "На вас немає такого типу предмета.",
    ["Another mouse button clicked the action button."] = "По кнопці дії клацнули іншою кнопкою миші.",
    ["Your action bar is on another page."] = "Панель дій на іншій сторінці.",
    ["No bonus bar is up, or not that one."] = "Бонусної панелі немає, або не ця.",
    ["The extra action button is not shown."] = "Додаткову кнопку дії не показано.",
    ["No override bar replaces your action bar."] = "Вашу панель дій не замінює інша панель.",
    ["You don't control another creature."] = "Ви не керуєте іншою істотою.",
    ["You are not in a vehicle with its own action bar."] = "Ви не в транспорті з власною панеллю дій.",
    ["The unit is not in a vehicle."] = "Юніт не в транспорті.",
    ["You can't leave a vehicle now."] = "Ви не можете зараз вийти з транспорту.",
    ["You are not in a pet battle."] = "Ви не в бою улюбленців.",
    ["Nothing is on the mouse cursor."] = "На курсорі миші нічого немає.",
    ["When the sequence starts over: seconds without a press, target, combat, shift, ctrl or alt."] =
        "Коли послідовність починається спочатку: секунди без натискань, target, combat, shift, ctrl або alt.",
    ["Ride a mount"] = "Сісти на маунта",
    ["One button for all your mounts: a flying one where you can fly, a ground one elsewhere, a swimming one in water. Press it again to get off."] = "Одна кнопка для всіх ваших маунтів: летючий там, де можна літати, наземний деінде, водний у воді. Натисніть ще раз, щоб злізти.",
    ["Mount"] = "Маунт",
    ["mount"] = "маунт",
    ["Which mount should the macro summon?"] = "Якого маунта має викликати макрос?",
    ["This one works anywhere. Next you can pick others for flying and for water."] = "Цей працюватиме будь-де. Далі можна вибрати інших для польотів і для води.",
    ["Which mount where you can fly?"] = "Якого маунта там, де можна літати?",
    ["Pick a flying mount, or leave it empty to use the same one."] = "Виберіть летючого маунта або залиште порожнім, щоб брати того самого.",
    ["Which mount in water?"] = "Якого маунта у воді?",
    ["Pick one that's fast in water, or leave it empty to use the others."] = "Виберіть того, хто швидкий у воді, або залиште порожнім, щоб брати тих самих.",
    ["What should a press do while you're mounted?"] = "Що робити, якщо натиснути, коли ви вже на маунті?",
    ["Dismount, but not while flying"] = "Злізти, але не в польоті",
    ["Dismount, even while flying"] = "Злізти, навіть у польоті",
    ["Which mount instead?"] = "Якого маунта замість нього?",
    ["For example, a ground mount in a flying zone. Leave it empty to skip this key."] = "Наприклад, наземного там, де можна літати. Залиште порожнім, якщо ця клавіша не потрібна.",
    ["Where you can fly"] = "Де можна літати",
    ["In water"] = "У воді",
    ["When mounted"] = "Коли на маунті",
    ["What pressing the macro does while you're mounted. Dismounting in the air means falling."] = "Що робить натискання, коли ви на маунті. Злізти в повітрі означає впасти.",
    ["type a mount"] = "введіть маунта",
    ["the same one"] = "той самий",
    ["a mount"] = "маунт",
    ["none"] = "немає",
    ["When"] = "Коли",
    ["Otherwise"] = "Інакше",
    ["otherwise: do nothing"] = "інакше: нічого",
    ["nothing"] = "нічого",
    ["What the macro casts when the conditions on the left aren't met. Leave it empty to do nothing then."] = "Що макрос застосовує, коли умови ліворуч не виконуються. Залиште порожнім, щоб тоді нічого не робити.",
    ["Should the macro work only at certain times?"] = "Макрос має працювати лише за певних умов?",
    ["Leave everything as is to make it always work. The rest of the time the macro does nothing, unless you choose something for it next."] = "Лишіть усе як є, щоб макрос працював завжди. Решту часу він нічого не робить, якщо далі ви не виберете, що робити.",
    ["And what should it cast the rest of the time?"] = "А що застосовувати в решті випадків?",
    ["Leave it empty to do nothing then."] = "Залиште порожнім, щоб тоді нічого не робити.",
    ["In or out of combat"] = "У бою чи поза ним",
    ["In combat"] = "У бою",
    ["Out of combat"] = "Поза боєм",
    ["In stealth or not"] = "У стелсі чи ні",
    ["In stealth"] = "У стелсі",
    ["Not in stealth"] = "Не в стелсі",
    ["In a group or alone"] = "У групі чи сам",
    ["In a group"] = "У групі",
    ["In a raid"] = "У рейді",
    ["Alone"] = "Сам",
    ["With a pet or not"] = "З улюбленцем чи без",
    ["Your pet is out"] = "Улюбленець викликаний",
    ["No pet out"] = "Улюбленця немає",
    ["In any form or none"] = "У будь-якій формі чи без",
    ["In no form"] = "Без форми",
    ["Put on gear"] = "Вдягнути спорядження",
    ["Swap weapons, trinkets or rings, or put on an equipment set: always, or with a key held."] = "Змінити зброю, трінкети чи кільця або вдягнути комплект: завжди чи з затиснутою клавішею.",
    ["Gear"] = "Спорядження",
    ["Put on"] = "Вдягнути",
    ["Set"] = "Комплект",
    ["No set"] = "Без комплекту",
    ["Put on one of your equipment sets?"] = "Вдягнути один із ваших комплектів?",
    ["These are your sets from the game's equipment manager. You can add single items after this."] = "Це ваші комплекти з менеджера спорядження гри. Окремі предмети можна додати далі.",
    ["Which item should the macro put on?"] = "Який предмет має вдягати макрос?",
    ["And another one?"] = "А ще один?",
    ["Leave it empty if that's all."] = "Залиште порожнім, якщо це все.",
    ["\"Default slot\" lets the game choose. For trinkets, rings and weapons you can pick the slot yourself."] = "«Звичайний слот» — гра вибере сама. Для трінкетів, кілець і зброї слот можна вибрати самому.",
    ["When should the macro put on %s?"] = "Коли макрос має вдягати %s?",
    ["Gear from your bags or what you're wearing. \"Default slot\" lets the game choose; for trinkets, rings and weapons you can pick the slot yourself (/equipslot 14). Each item can go on always or only with a key held."] = "Спорядження із сумок або те, що на вас. «Звичайний слот» — гра вибере сама; для трінкетів, кілець і зброї слот можна вибрати самому (/equipslot 14). Кожен предмет можна вдягати завжди або лише з затиснутою клавішею.",
    ["type an item"] = "введіть предмет",
    ["Default slot"] = "Звичайний слот",
    ["Main hand"] = "Основна рука",
    ["Off hand"] = "Друга рука",
    ["Ring 1"] = "Кільце 1",
    ["Ring 2"] = "Кільце 2",
    ["Always"] = "Завжди",
    ["With Shift held"] = "З затиснутим Shift",
    ["With Ctrl held"] = "З затиснутим Ctrl",
    ["With Alt held"] = "З затиснутим Alt",
    ["With Cmd held"] = "З затиснутим Cmd",
    ["Without a key"] = "Без клавіші",
    -- Open in Wizard
    ["Open in Wizard"] = "Відкрити в майстрі",
    ["Wizard"] = "У майстрі",
    ["Change macro (Wizard)"] = "Зміна макроса (майстер)",
    ["Put in editor"] = "Вставити в редактор",
    ["Lines that will change"] = "Рядки, які зміняться",
    ["%d lines will change"] = { "%d рядок зміниться", "%d рядки зміняться", "%d рядків зміниться" },
    ["The wizard writes these lines of your macro its own way, or can't keep them. You get the text shown above. "
        .. "Your macro doesn't change until you put that text in the editor. Even then, %s undoes it."] =
        "Ці рядки вашого макроса майстер пише по-своєму або не може зберегти. Ви отримаєте текст, показаний вище. "
        .. "Ваш макрос не зміниться, доки ви не вставите цей текст у редактор. Але навіть тоді %s усе поверне.",
    ["Opens this macro in the wizard, so you can change it with a few clicks. The new text comes back here, and "
        .. "Save keeps it."] = "Відкриває цей макрос у майстрі, щоб змінити його кількома кліками. Новий текст "
        .. "повернеться сюди, а «Зберегти» його збереже.",
    ["The wizard can't read this macro. It makes macros that cast a spell, use an item, target someone, command "
        .. "your pet, summon a mount or put on gear."] = "Майстер не може прочитати цей макрос. Він уміє робити "
        .. "макроси, які застосовують заклинання чи предмет, беруть когось у ціль, керують улюбленцем, викликають "
        .. "маунта або вдягають спорядження.",
    ["%d lines will come out different or be left out."] = { "%d рядок вийде інакшим або зникне.",
        "%d рядки вийдуть інакшими або зникнуть.", "%d рядків вийдуть інакшими або зникнуть." },
}
