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
    ["/ms - open the editor; /ms help - the macro guide; /ms book - macros from the spellbook; /ms sets - macro sets; "
        .. "/ms settings - settings; /ms minimap - hide or show the minimap button; /ms bug - details for a bug report; "
        .. "/ms autocomplete | debug - toggle"] =
        "/ms — відкрити редактор; /ms help — довідка з макросів; /ms book — макроси з книги заклинань; /ms sets — набори "
        .. "макросів; /ms settings — налаштування; /ms minimap — сховати чи показати кнопку біля мінікарти; /ms bug — "
        .. "подробиці для звіту про помилку; /ms autocomplete | debug — увімкнути чи вимкнути",
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
    ["Pick the \"Character\" tab and press \"New\". The new macro already has #showtooltip on its first line, and "
        .. "the cursor waits on the second."] =
        "Виберіть вкладку «Персонаж» і натисніть «Новий». У новому макросі вже є #showtooltip у першому рядку, а "
        .. "курсор стоїть на другому.",
    ["Type a name, such as Bolt MO (MO for mouseover), and press Tab."] =
        "Введіть назву, наприклад Bolt MO (MO — це mouseover, «під мишею»), і натисніть Tab.",
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
    ["Press \"Save\", then drag the macro from the list onto an action bar. Done."] =
        "Натисніть «Зберегти» і перетягніть макрос зі списку на панель дій. Готово.",
    ["In combat the game doesn't let you change macros. \"Save\" then keeps your change, and the macro is saved as "
        .. "soon as combat ends."] =
        "У бою гра не дає змінювати макроси. Тоді «Зберегти» запам'ятає зміну, і макрос збережеться одразу після "
        .. "бою.",
    ["New macro"] = "Новий макрос",
    ["The wizard"] = "Майстер",
    ["You don't have to write anything: \"New (Wizard)\" makes the macro for you."] =
        "Писати нічого не обов'язково: «Майстер» зробить макрос за вас.",
    ["Step by step, it asks one question at a time: what the macro should do, which spell, on whom, and if not, on "
        .. "whom then, what Shift, Ctrl or Alt change, when it works. \"All options\" shows the whole form at once "
        .. "instead."] =
        "Покроково він ставить по одному питанню: що має робити макрос, яке заклинання, на кого, а якщо ні — то на "
        .. "кого тоді, що змінюють Shift, Ctrl чи Alt, коли він працює. «Усі параметри» натомість показують усю "
        .. "форму одразу.",
    ["The macro grows in the wizard as you answer. \"Create macro\" saves it and opens it in the editor."] =
        "Поки ви відповідаєте, макрос з'являється в майстрі. «Створити» зберігає його й відкриває в редакторі.",
    ["To change a macro you have with the same questions, open it and press \"Wizard\"."] =
        "Щоб змінити наявний макрос тими самими питаннями, відкрийте його й натисніть «У майстрі».",
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
    ["Two more things you will meet in macros:"] = "Ще дві речі, які трапляються в макросах:",
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
    ["The editor warns about a part that never runs: one after [], or a spell with the global cooldown below a line "
        .. "that always casts one. When a key chooses it, Ctrl+click on the warning puts it first."] =
        "Редактор попереджає про частину, що ніколи не спрацює: після [] або заклинання з глобальним кулдауном під "
        .. "рядком, що завжди кастує таке. Коли її вибирає клавіша, Ctrl+клік по попередженню ставить її першою.",
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
    ["255 characters at most. \"Shorten\" writes the same macro in fewer."] =
        "Щонайбільше 255 символів. «Скоротити» записує той самий макрос коротше.",
    ["Cast from /run"] = "Кастувати з /run",
    ["/run and /script run small programs: they can show text or change game settings, but can't cast a spell or "
        .. "target anyone."] =
        "/run і /script запускають маленькі програми: вони можуть показати текст чи змінити налаштування гри, але "
        .. "не можуть кастувати заклинання чи брати когось у ціль.",
    ["Ready-made macros"] = "Готові макроси",
    ["\"Create\" puts the macro into the tab that is open, under a free name, and opens it. Change the spell names "
        .. "to yours."] =
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
    -- Practice (Practice.lua, HelpWindow)
    ["Practice"] = "Практика",
    ["A few tasks with your own spells. Write each macro in the editor: press \"New\" there, write it, then press "
        .. "\"Check\" here. \"Answer\" shows one way to write it."] =
        "Кілька завдань із вашими власними заклинаннями. Пишіть кожен макрос у редакторі: натисніть там «Новий», "
        .. "напишіть його, а потім натисніть «Перевірити» тут. «Відповідь» показує один зі способів його написати.",
    ["The tasks need a spell of yours for enemies. Learn one, then open this section again."] =
        "Для завдань потрібне ваше заклинання проти ворогів. Вивчіть таке й відкрийте цей розділ знову.",
    ["Task %d"] = "Завдання %d",
    ["done"] = "виконано",
    ["Check"] = "Перевірити",
    ["Answer"] = "Відповідь",
    ["One way to write it:"] = "Один зі способів:",
    ["The macro should cast with /cast."] = "Макрос має кастувати через /cast.",
    ["The macro casts %s; the task wants %s."] = "Макрос кастує %s, а завдання просить %s.",
    ["Cast %s at the enemy under your mouse, or at your target when you point at nobody."] =
        "Кастуйте %s у ворога під мишею, а якщо там нікого немає — у вашу ціль.",
    ["First, the macro should go to the unit under the mouse: @mouseover."] =
        "Спершу макрос має йти на того, хто під мишею: @mouseover.",
    ["When nobody is under the mouse, it should go to your target: add [] after the first brackets."] =
        "Коли під мишею нікого немає, він має йти у вашу ціль: додайте [] після перших дужок.",
    ["Add harm next to @mouseover, so the macro casts at the unit under the mouse only when it is an enemy."] =
        "Додайте harm поруч із @mouseover, щоб макрос кастував у того, хто під мишею, лише коли це ворог.",
    ["Cast %s as usual, and %s on your focus while you hold Shift."] =
        "Кастуйте %s як зазвичай, а поки ви тримаєте Shift — %s на ваш фокус.",
    ["With Shift held, the macro should cast %s: [mod:shift] before it."] =
        "Із затиснутим Shift макрос має кастувати %s: [mod:shift] перед ним.",
    ["With Shift held, the macro casts %s; the task wants %s."] =
        "Із затиснутим Shift макрос кастує %s, а завдання просить %s.",
    ["With Shift held, %s should go to your focus: @focus."] = "Із затиснутим Shift %s має йти на ваш фокус: @focus.",
    ["Without Shift, the spell should go to your target, as usual."] =
        "Без Shift заклинання має йти у вашу ціль, як зазвичай.",
    ["Stop whatever you are casting, then cast %s at your focus, or at your target when you have no focus."] =
        "Перервіть те, що кастуєте, а потім кастуйте %s у ваш фокус, а якщо фокуса немає — у вашу ціль.",
    ["Add /stopcasting on a line before the cast."] = "Додайте /stopcasting окремим рядком перед кастом.",
    ["First, the macro should go to your focus: @focus."] = "Спершу макрос має йти на ваш фокус: @focus.",
    ["When you have no focus, it should go to your target: add harm next to @focus, then []."] =
        "Коли фокуса немає, він має йти у вашу ціль: додайте harm поруч із @focus, а потім [].",
    ["Cast %s, then %s, one each press, starting over on a new target."] =
        "Кастуйте %s, потім %s, по одному за натискання, і починайте з початку на новій цілі.",
    ["The macro should use /castsequence."] = "Макрос має використовувати /castsequence.",
    ["The list should be %s, then %s, split by a comma."] = "Список має бути таким: %s, потім %s, через кому.",
    ["It should start over on a new target: reset=target."] =
        "Він має починатися з початку на новій цілі: reset=target.",
    ["Send your pet to attack the enemy under your mouse, or your target when you point at nobody."] =
        "Пошліть улюбленця атакувати ворога під мишею, а якщо там нікого немає — вашу ціль.",
    ["The macro should send your pet with /petattack."] = "Макрос має посилати улюбленця через /petattack.",
    ["First, the pet should go to the unit under the mouse: @mouseover."] =
        "Спершу улюбленець має йти на того, хто під мишею: @mouseover.",
    ["Add harm next to @mouseover, so the pet goes only for an enemy."] =
        "Додайте harm поруч із @mouseover, щоб улюбленець ішов лише на ворога.",
    ["Cast %s on a friend under your mouse; if there is none, on your target if it is a friend; if not, on yourself."] =
        "Кастуйте %s на друга під мишею; якщо там нікого немає — на вашу ціль, якщо вона друг; інакше — на себе.",
    ["Then to your target, if it is a friend: [help] with no @, after the first brackets."] =
        "Потім на вашу ціль, якщо вона друг: [help] без @, після перших дужок.",
    ["Last, to yourself: [@player]."] = "Останнім — на себе: [@player].",
    ["Add help to the brackets, so the macro casts only at friends."] =
        "Додайте help у дужки, щоб макрос кастував лише на друзів.",
    ["Write the macro in the editor first."] = "Спершу напишіть макрос у редакторі.",
    ["This macro is not one the task asks for. Start from the task's words, line by line."] =
        "Це не той макрос, який просить завдання. Почніть зі слів завдання, рядок за рядком.",
    ["Right: the macro does what the task asks."] = "Правильно: макрос робить те, що просить завдання.",
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
    ["In-game"] = "Як у грі",
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
    ["Duplicate"] = "Дублювати",
    ["Copy to Character"] = "Копіювати в «Персонаж»",
    ["Copy to General"] = "Копіювати в «Загальні»",
    ["Move to Character"] = "Перенести в «Персонаж»",
    ["Move to General"] = "Перенести в «Загальні»",
    ["It leaves this tab and goes there. Hold Ctrl to copy it instead."] =
        "Макрос іде з цієї вкладки туди. Затисніть Ctrl, щоб скопіювати його натомість.",
    ["It is in this tab already."] = "Макрос уже в цій вкладці.",
    ["Copy, move and more"] = "Копіювати, перенести та інше",
    ["Tabs"] = "Вкладки",
    ["Drag a macro onto the General or Character tab to move it there, or with Ctrl to copy it. A macro behind the "
        .. "scenes goes onto General only: it is this character's already. This works with macro sets off too."] =
        "Перетягніть макрос на вкладку «Загальні» чи «Персонаж», щоб перенести його туди, або з Ctrl, щоб "
        .. "скопіювати. Макрос за лаштунками можна перетягнути лише на «Загальні»: персонажу він уже належить. "
        .. "Це працює й з вимкненими наборами.",
    ["It is this character's already. To bring it into the game, drag it onto \"In the game\" or use \"Take in\"."] =
        "Цей макрос уже належить персонажу. Щоб вивести його в гру, перетягніть його на «У грі» або оберіть "
        .. "«Взяти в гру».",
    ["For a macro behind the scenes: a copy in the same set, named like \"Fear 2\". A macro behind the scenes can "
        .. "also be moved or copied to the General tab from here."] =
        "Для макроса за лаштунками: копія в тому самому наборі з назвою на кшталт «Fear 2». Звідси ж макрос за "
        .. "лаштунками можна перенести або скопіювати у вкладку «Загальні».",
    ["Makes a copy in the same set, behind the scenes, named like \"Fear 2\"."] =
        "Створює копію в тому самому наборі, за лаштунками, з назвою на кшталт «Fear 2».",
    ["Makes a copy for all your characters, named like \"Fear 2\". This one stays where it is."] =
        "Створює копію для всіх ваших персонажів, з назвою на кшталт «Fear 2». Цей макрос лишається, де був.",
    ["Into the General tab, for all your characters: it leaves its set and comes into the game. Its history goes "
        .. "with it."] =
        "У вкладку «Загальні», для всіх ваших персонажів: макрос іде зі свого набору й з'являється в грі. Його "
        .. "історія переходить разом із ним.",
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
    ["Its own macros, those behind the scenes too, as they were when you last played it: %s. Click to show or hide "
        .. "them."] =
        "Усі його макроси, і ті, що за лаштунками, такими, як були, коли ви востаннє ним грали: %s. Клацніть, щоб "
        .. "показати чи сховати їх.",
    ["Behind the scenes there, in \"%s\"."] = "У нього за лаштунками, у «%s».",
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
    ["With mistakes"] = "З помилками",
    ["Only the macros with a mistake (red) or a warning (yellow): every macro is checked. The tabs say how many each has. Point at a macro to read what is wrong, click it to fix it."] =
        "Лише макроси з помилкою (червоні) чи попередженням (жовті): аддон перевіряє всі макроси. Вкладки "
        .. "показують, скільки таких у кожній. Наведіть мишу на макрос, щоб прочитати, що не так, і клацніть, "
        .. "щоб виправити.",
    ["No mistakes found"] = "Помилок не знайдено",
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
    ["No specialization yet"] = "Ще без спеціалізації",
    ["(full)"] = "(заповнена)",
    ["(behind the scenes)"] = "(за лаштунки)",
    ["All 30 slots are taken: it goes behind the scenes, in \"This character's\"."] =
        "Усі 30 слотів зайняті: макрос піде за лаштунки, у «Цього персонажа».",
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
        .. "number is added to it, like \"Fear 2\". Macro sets come from a code too, or from another character of "
        .. "yours."] =
        "Вставте код або текст макроса з гайду, щоб додати його макроси. Нічого не заміниться: якщо назву вже "
        .. "зайнято, до неї додасться номер, як «Fear 2». Набори макросів теж можна взяти з коду або з іншого "
        .. "вашого персонажа.",
    ["Export macro sets..."] = "Експортувати набори макросів...",
    ["The code of your macro sets: you choose which. Import it on another character, or share it."] =
        "Код ваших наборів макросів, вибираєте, яких саме. Імпортуйте його на іншому персонажі або поділіться ним.",
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
    ["Saves all your macros now: General, this character's, and those behind the scenes. Each character keeps its "
        .. "last %d backups; older ones are deleted by themselves."] =
        "Зберігає всі ваші макроси просто зараз: загальні, цього персонажа й ті, що за лаштунками. Для кожного "
        .. "персонажа лишаються останні %d бекапів, старіші видаляються самі.",
    ["%d macros"] = { "%d макрос", "%d макроси", "%d макросів" },
    ["Backup of %s"] = "Бекап: %s",
    ["General %d, Character %d. Click to restore it."] = "Загальних: %d, персонажа: %d. Клацніть, щоб відновити.",
    ["General %d, Character %d, behind the scenes %d. Click to restore it."] =
        "Загальних: %d, персонажа: %d, за лаштунками: %d. Клацніть, щоб відновити.",
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
    ["The same as the text now."] = "Такий самий, як текст зараз.",
    ["Note on \"%s\""] = "Нотатка до «%s»",
    ["Replace"] = "Замінити",
    ["%d picked"] = { "Вибрано %d", "Вибрано %d", "Вибрано %d" },
    ["Pick"] = "Вибір",
    ["A check before each macro and each group: one click picks a macro or a whole group, another click takes it back. Then share, move, put into a set or delete them all at once."] =
        "Галочка біля кожного макросу й кожної групи: один клік вибирає макрос чи всю групу, ще один — знімає "
        .. "вибір. Потім ними можна поділитися, перенести їх, додати в набір чи видалити всі одразу.",
    ["All"] = "Усі",
    ["What if"] = "Що, як...",
    ["The notes next to the lines for a moment you set up: the keys held, combat, and who your target, mouseover and focus are. With the editor open your mouse can't be over someone, so this is how to check a mouseover macro. Anything else the macro checks is as in the game now."] =
        "Підказки біля рядків для моменту, який ви задаєте самі: затиснуті клавіші, бій, і хто ваша ціль, хто "
        .. "під мишею і хто у фокусі. Поки відкритий редактор, миша не може бути над кимось у світі, тож так "
        .. "перевіряють макрос із маусовером. Усе інше, що перевіряє макрос, — як у грі зараз.",
    ["set up the keys, the target and the mouseover yourself"] = "задайте клавіші, ціль і маусовер самі",
    ["Nobody"] = "Нікого",
    ["won't cast: you have no target"] = "не скастується: у вас немає цілі",
    ["won't cast: nobody is under the mouse"] = "не скастується: під мишею нікого",
    ["won't cast: you have no focus"] = "не скастується: у вас немає фокуса",
    ["the target"] = "ціль",
    ["the mouseover"] = "маусовер",
    ["the focus"] = "фокус",
    ["won't cast: %s is a friend"] = "не скастується: %s — друг",
    ["won't cast: %s is a dead enemy"] = "не скастується: %s — мертвий ворог",
    ["won't cast: %s is an enemy"] = "не скастується: %s — ворог",
    ["An enemy"] = "Ворог",
    ["A friend"] = "Друг",
    ["A dead enemy"] = "Мертвий ворог",
    ["Favorites"] = "Улюблені",
    ["The macros you marked as favorites: always at the top."] = "Макроси, які ви позначили як улюблені: завжди вгорі.",
    ["A folder of your own. A right click renames or deletes it; \"...\" on a macro puts it in or takes it out."] =
        "Ваша власна тека. Правий клік перейменовує чи видаляє її; «...» на макросі кладе його в теку чи виймає.",
    ["Add to favorites"] = "Додати до улюблених",
    ["Remove from favorites"] = "Прибрати з улюблених",
    ["Into the folder: %s"] = "У теку: %s",
    ["Into a new folder"] = "У нову теку",
    ["A new folder"] = "Нова тека",
    ["Out of the folder"] = "Вийняти з теки",
    ["Into \"%s\""] = "У «%s»",
    ["Rename the folder"] = "Перейменувати теку",
    ["Delete the folder"] = "Видалити теку",
    ["Delete the folder \"%s\"? Its macros stay, out of any folder."] =
        "Видалити теку «%s»? Її макроси лишаться, просто поза теками.",
    ["there is a folder of that name already"] = "тека з такою назвою вже є",
    ["the folder needs a name"] = "теці потрібна назва",
    ["Actions"] = "Дії",
    ["Pick all in the list"] = "Вибрати всі в переліку",
    ["Clear the picks"] = "Зняти вибір",
    ["Pick this group"] = "Вибрати всю групу",
    ["Move %d from %s to %s"] = "Перенести %d з «%s» у «%s»",
    ["Take in %d"] = "Взяти в гру: %d",
    ["Put away %d"] = "За лаштунки: %d",
    ["took in %d macros"] = { "взято в гру %d макрос", "взято в гру %d макроси", "взято в гру %d макросів" },
    ["put away %d macros"] = { "за лаштунки пішов %d макрос", "за лаштунки пішли %d макроси",
        "за лаштунки пішли %d макросів" },
    ["%d of them stay behind the scenes: the game has a macro of the same name"] =
        "%d з них лишилися за лаштунками: у грі вже є макрос із такою назвою",
    ["Into: %s"] = "У набір: %s",
    ["moved %d macros"] = { "перенесено %d макрос", "перенесено %d макроси", "перенесено %d макросів" },
    ["no free slots for %d of them: they stay where they were"] =
        "для %d з них немає вільних слотів: вони лишилися, де були",
    ["%d macros put in"] = { "додано %d макрос", "додано %d макроси", "додано %d макросів" },
    ["Delete %s? Those in the game go into the trash."] = "Видалити %s? Ті, що в грі, потраплять у кошик.",
    ["Find and replace"] = "Знайти й замінити",
    ["Changes a word or a spell in many macros at once, in the groups you choose. Each macro's History keeps the text it had."] =
        "Змінює слово чи заклинання в багатьох макросах одразу, у вибраних групах. Історія кожного макросу "
        .. "зберігає текст, який у нього був.",
    ["Find"] = "Знайти",
    ["Replace with"] = "Замінити на",
    ["As typed: big and small letters count."] = "Як набрано: великі й малі літери різні.",
    ["Where"] = "Де",
    ["Replace all"] = "Замінити все",
    ["Type what to find."] = "Наберіть, що знайти.",
    ["Nothing found."] = "Нічого не знайдено.",
    ["%d matches"] = { "%d збіг", "%d збіги", "%d збігів" },
    ["in %d macros"] = { "у %d макросі", "у %d макросах", "у %d макросах" },
    ["changed %d macros: their History keeps the texts they had"] = {
        "змінено %d макрос: його історія зберігає текст, який у нього був",
        "змінено %d макроси: їхня історія зберігає тексти, які в них були",
        "змінено %d макросів: їхня історія зберігає тексти, які в них були" },
    ["left as they are, they would be longer than %d characters: %s"] =
        "лишилися як були, бо стали б довшими за %d символів: %s",
    ["Add a note"] = "Додати нотатку",
    ["Change the note"] = "Змінити нотатку",
    ["If you pick it, the text changes like this:"] = "Якщо вибрати цю версію, текст зміниться так:",
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
    ["Saves when combat ends"] = "Збережеться після бою",
    ["Macro is longer than %d characters"] = "Макрос довший за %d символів",
    ["Ln %d, Col %d"] = "Рядок %d, стовпець %d",
    ["Line %d: %s"] = "Рядок %d: %s",
    [" (+%d more)"] = " (+ще %d)",
    ["Ctrl+click to use \"%s\""] = "Ctrl+клік, щоб вставити «%s»",
    ["Click to go to line %d"] = "Клацніть, щоб перейти до рядка %d",
    ["Ctrl+click to add \"%s\""] = "Ctrl+клік, щоб додати «%s»",
    ["Ctrl+click to remove \"%s\""] = "Ctrl+клік, щоб прибрати «%s»",
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
    ["\"%s\" will be saved when combat ends: the game doesn't let you change macros in combat"] =
        "«%s» збережеться після бою: у бою гра не дає змінювати макроси",
    ["\"%s\" saved after combat"] = "«%s» збережено після бою",
    ["could not save \"%s\" after combat"] = "не вдалося зберегти «%s» після бою",
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
    ["Paste a MacroSense code, or a macro's text from a guide (%s), or choose a character of yours. Nothing gets "
        .. "replaced: if a name is taken, a number is added to it."] =
        "Вставте код MacroSense або текст макроса з гайду (%s), або виберіть свого персонажа. Нічого не заміниться: "
        .. "якщо назву вже зайнято, до неї додасться номер.",
    ["Or from a character..."] = "Або з персонажа...",
    ["Export macro sets"] = "Експорт наборів макросів",
    ["Check the sets to export. Press %s to copy the code: import it on another character, or share it."] =
        "Позначте набори для експорту. Натисніть %s, щоб скопіювати код: імпортуйте його на іншому персонажі або "
        .. "поділіться ним.",
    ["Check the sets to export."] = "Позначте набори для експорту.",
    ["%d macros in %d sets"] = "Макросів: %d, наборів: %d",
    ["Select all"] = "Вибрати все",
    ["Clear all"] = "Зняти все",
    ["Macro sets of %s: %d macros"] = "Набори макросів: %s, макросів: %d",
    ["%d new"] = { "%d новий", "%d нові", "%d нових" },
    ["%d here already"] = { "%d вже є тут", "%d вже є тут", "%d вже є тут" },
    ["%d too long"] = { "%d задовгий", "%d задовгі", "%d задовгих" },
    ["%s > This character's"] = "%s > «Цього персонажа»",
    ["These are the sets of another class (%s): its specializations aren't yours, so all the macros go into "
        .. "\"This character's\"."] =
        "Це набори іншого класу (%s): його спеціалізації не ваші, тож усі макроси підуть у «Цього персонажа».",
    ["Turn on \"Macro sets\" first: these macros go into them."] =
        "Спершу ввімкніть «Набори макросів»: ці макроси підуть саме туди.",
    ["They come in behind the scenes: take in those you need."] =
        "Вони прийдуть за лаштунки: візьміть у гру ті, що потрібні.",
    ["turn on \"Macro sets\" first: the macros go into them"] =
        "спершу ввімкніть «Набори макросів»: макроси підуть саме туди",
    ["imported %d macros into the sets, behind the scenes: take in those you need"] =
        "імпортовано в набори, за лаштунки, макросів: %d. Візьміть у гру ті, що потрібні",
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
    ["Dead only"] = "Лише мертві",
    ["Dead or alive"] = "Живі чи мертві",
    ["Alive or dead"] = "Живі чи мертві",
    ["Dead only is for a resurrection: the macro skips those alive. Yourself, As usual and At the cursor aren't "
        .. "checked."] = "«Лише мертві» — для воскресіння: живих макрос пропускає. Себе, «As usual» і «At the cursor» "
        .. "не перевіряють.",
    ["With a key held"] = "З клавішею",
    ["same spell"] = "те саме заклинання",
    ["macOS uses some keys with Cmd itself: Tab switches apps, Space opens Spotlight, and others do things too. "
        .. "On those keys macOS acts first, so the editor warns you when the macro is on one."] =
        "Деякі клавіші з Cmd macOS використовує сама: Tab перемикає програми, Space відкриває Spotlight, інші теж "
        .. "щось роблять. На таких клавішах першою спрацьовує macOS, тож редактор попередить, якщо макрос стоїть "
        .. "на одній із них.",
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
    ["Don't turn it off"] = "Не вимикати повторно",
    ["Puts ! before the spell (!Shoot). Pressed again, the macro doesn't turn off what it turned on: Auto Shot, a wand's Shoot, Stealth, a form or an aura."] =
        "Ставить ! перед заклинанням (!Shoot). Якщо натиснути макрос ще раз, він не вимкне те, що увімкнув: "
        .. "Auto Shot, Shoot із жезла, стелс, форму чи ауру.",
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
    ["Dead friends"] = "Мертві друзі",
    ["For a resurrection: the macro skips those alive."] = "Для воскресіння: живих макрос пропускає.",
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
    ["Or the one there is not a friend, or is alive."] = "Або той, хто там є, не друг чи живий.",
    ["Or the one there is not an enemy, or is alive."] = "Або той, хто там є, не ворог чи живий.",
    ["Or the one there is alive."] = "Або той, хто там є, живий.",
    ["What name should it look for?"] = "Яке ім'я шукати?",
    ["The nearest one with this name becomes your target, such as a rare."] =
        "Вашою ціллю стане найближчий з таким ім'ям, наприклад рідкісний монстр.",
    ["Should the macro do something else while you hold %s?"] =
        "Чи має макрос робити щось інше, поки ви тримаєте %s?",
    ["Pick the keys you want, or none. For each key, the next questions ask what it does."] =
        "Оберіть потрібні клавіші або жодної. Для кожної далі буде питання, що вона робить.",
    ["With %s held"] = "Із затиснутим %s",
    ["With Shift and Ctrl held"] = "Із затиснутими Shift і Ctrl",
    ["On a right click"] = "Правим кліком",
    ["Right click"] = "Правий клік",
    ["Two keys, right click"] = "Дві клавіші, правий клік",
    ["Rows for Shift and Ctrl held together ([mod:shift,mod:ctrl]) and for a right click on the macro's button "
        .. "([btn:2]), each with its own spell or units, as a key."] = "Рядки для Shift і Ctrl, затиснутих разом "
        .. "([mod:shift,mod:ctrl]), і для правого кліку по кнопці макросу ([btn:2]): кожен зі своїм спелом чи "
        .. "юнітами, як клавіша.",
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
    ["the editor couldn't open because of an error: %s. Please send this line and what /ms bug shows"] =
        "редактор не відкрився через помилку: %s. Надішліть, будь ласка, цей рядок і те, що покаже /ms bug",
    ["condition \"%s\" doesn't work in this version of the game"] =
        "умова «%s» не працює в цій версії гри",
    ["never runs: the part before it always does (it has [] or no conditions). Put this part before it"] =
        "ніколи не спрацює: частина перед нею спрацьовує завжди (у неї [] або немає умов). Поставте цю частину "
        .. "перед нею",
    ["never runs"] = "ніколи не спрацює",
    ["won't cast: the line above always casts %s first, and its global cooldown stops this one. To choose between "
        .. "them, put both into one /cast, this part first"] = "не скаститься: рядок вище завжди спершу кастує %s, і "
        .. "його глобальний кулдаун зупиняє цей. Щоб вибирати між ними, поставте обидва в один /cast, цю частину "
        .. "першою",
    ["won't cast"] = "не скаститься",
    ["Ctrl+click to put the parts with a key first"] = "Ctrl+клік, щоб поставити частини з клавішею першими",
    ["Ctrl+click to put this line into the line above, first"] =
        "Ctrl+клік, щоб перенести цей рядок у рядок вище, на початок",
    ["Ctrl+click to fix it"] = "Ctrl+клік — виправити",
    ["works only while %s is on cooldown: the line above always casts it first, and its global cooldown stops this "
        .. "one. To choose with a key, put both into one /cast, this part first"] = "спрацює лише поки %s на "
        .. "кулдауні: рядок вище завжди спершу кастує його, і його глобальний кулдаун зупиняє цей. Щоб вибирати "
        .. "клавішею, поставте обидва в один /cast, цю частину першою",
    ["only while %s is on cooldown"] = "лише поки %s на кулдауні",
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
    ["talent"] = "талант",
    ["learned later"] = "вивчите пізніше",
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
    ["inside, plot, editor or neighborhood"] = "inside, plot, editor або neighborhood",
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
    ["switches the action bar between pages %s and %s"] = "перемикає панель дій між сторінками %s і %s",
    ["places the %s marker at the cursor"] = "ставить маркер «%s» під курсор",
    ["places the %s marker under %s"] = "ставить маркер «%s» під %s",
    ["places the %s marker where you click"] = "ставить маркер «%s» туди, куди ви клацнете",
    ["clears the %s marker"] = "прибирає маркер «%s»",
    ["clears every world marker"] = "прибирає всі маркери на землі",
    ["blue square"] = "синій квадрат",
    ["green triangle"] = "зелений трикутник",
    ["purple diamond"] = "фіолетовий ромб",
    ["red cross"] = "червоний хрест",
    ["yellow star"] = "жовта зірка",
    ["orange circle"] = "помаранчеве коло",
    ["silver moon"] = "срібний місяць",
    ["white skull"] = "білий череп",
    ["every marker"] = "усі маркери",
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
    ["the quest giver you are talking to"] = "квестодавця, з яким ви говорите",
    ["quest giver you talk to"] = "квестодавець, з яким ви говорите",
    ["The quest giver you are talking to, while its quest window is open."] =
        "Квестодавець, з яким ви говорите, поки відкрите його вікно завдань.",
    ["The same as anyinteract."] = "Те саме, що anyinteract.",
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
    ["where PvP talents work"] = "там, де діють PvP-таланти",
    ["where PvP talents don't work"] = "там, де PvP-таланти не діють",
    ["in a house or on its plot"] = "у будинку чи на його ділянці",
    ["away from a house"] = "не біля будинку",
    ["%s"] = "%s",
    ["not %s"] = "не %s",
    ["inside a house"] = "у будинку",
    ["on a house's plot"] = "на ділянці будинку",
    ["in the house editor"] = "у редакторі будинку",
    ["in a neighborhood"] = "у кварталі",
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
    ["self-cast key"] = "клавіша касту на себе",
    ["focus-cast key"] = "клавіша касту на фокус",
    ["with your self-cast key held"] = "із затиснутою клавішею касту на себе",
    ["without your self-cast key held"] = "без затиснутої клавіші касту на себе",
    ["with your focus-cast key held"] = "із затиснутою клавішею касту на фокус",
    ["without your focus-cast key held"] = "без затиснутої клавіші касту на фокус",
    ["mouseover-cast key"] = "клавіша касту на того, хто під курсором",
    ["action pick-up key"] = "клавіша, що знімає дії з панелей",
    ["auto-loot key"] = "клавіша автозбору здобичі",
    ["with your mouseover-cast key held"] =
        "із затиснутою клавішею касту на того, хто під курсором",
    ["without your mouseover-cast key held"] =
        "без затиснутої клавіші касту на того, хто під курсором",
    ["with your action pick-up key held"] =
        "із затиснутою клавішею, що знімає дії з панелей",
    ["without your action pick-up key held"] =
        "без затиснутої клавіші, що знімає дії з панелей",
    ["with your auto-loot key held"] = "із затиснутою клавішею автозбору здобичі",
    ["without your auto-loot key held"] =
        "без затиснутої клавіші автозбору здобичі",
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
    ["%s: edit in MacroSense"] = "%s: редагувати в MacroSense",
    ["right-click"] = "правий клік",
    ["middle-click"] = "середній клік",
    ["left-click"] = "лівий клік",
    ["Open a macro in MacroSense with a click on its button"] = "Відкривати макрос у MacroSense кліком по його кнопці",
    ["Combination:"] = "Комбінація:",
    ["Tag macro"] = "Тег-макрос",
    ["Instead of the game's macro window"] = "Замість вікна макросів гри",
    ["Open MacroSense with \"%s\" in the game menu"] = "Відкривати MacroSense кнопкою «%s» у меню гри",
    ["Open MacroSense with the %s command"] = "Відкривати MacroSense командою %s",
    ["this game doesn't tell which conditions it knows"] = "ця гра не каже, які умови вона знає",
    ["this game knows every condition MacroSense offers"] = "ця гра знає всі умови, які пропонує MacroSense",
    ["conditions this game doesn't know: %s"] = "умови, яких ця гра не знає: %s",
    ["Keys:"] = "Клавіші:",
    ["Hold them and click a creature or player: its name goes into your tag macro, which then targets it. A click on "
        .. "yourself takes the name out. A macro becomes the tag macro in its \"...\" menu."] =
        "Затисніть їх і клацніть по істоті чи гравцю: її ім'я потрапить у ваш тег-макрос, і він братиме її в ціль. "
        .. "Клік по собі прибирає ім'я. Тег-макросом макрос стає в його меню «...».",
    ["Make it the tag macro"] = "Зробити тег-макросом",
    ["Not the tag macro"] = "Більше не тег-макрос",
    ["Tag macro: %s + click on a creature or player puts its name in"] =
        "Тег-макрос: %s + клік по істоті чи гравцю вписує сюди її ім'я",
    ["tag macro \"%s\": hold %s and click a creature or player to put its name in"] =
        "тег-макрос «%s»: затисніть %s і клацніть по істоті чи гравцю, щоб вписати її ім'я",
    ["tag macro \"%s\": %s"] = "тег-макрос «%s»: %s",
    ["tag macro \"%s\": no name"] = "тег-макрос «%s»: без імені",
    ["tag macro \"%s\": %s, once combat ends"] = "тег-макрос «%s»: %s, щойно скінчиться бій",
    ["tag macro \"%s\": no name, once combat ends"] = "тег-макрос «%s»: без імені, щойно скінчиться бій",
    ["tag macro \"%s\": %s doesn't fit, the macro would be longer than %d characters"] =
        "тег-макрос «%s»: %s не вміщається, макрос був би довшим за %d символів",
    ["the tag macro \"%s\" is gone: pick another one in a macro's \"...\" menu"] =
        "тег-макросу «%s» більше немає: оберіть інший у меню «...» макросу",
    ["This click opens the macro instead of running it. Pick one your macros don't use, or turn it off."] =
        "Цей клік відкриває макрос, а не запускає його. Оберіть такий, якого ваші макроси не використовують, або "
        .. "вимкніть його.",
    ["Click: open or close the editor"] = "Клацання: відкрити чи закрити редактор",
    ["Drag: move the button"] = "Перетягування: перемістити кнопку",
    ["/ms minimap hides it"] = "/ms minimap ховає її",
    ["No icons"] = "Немає іконок",
    ["%d icons"] = { "%d іконка", "%d іконки", "%d іконок" },
    ["%s (looking up names: %d%%)"] = "%s (шукаю назви: %d%%)",
    ["Search by name"] = "Пошук за назвою",
    ["Name, file name or ID"] = "Назва, ім'я файлу чи ID",
    ["Finds icons by the names of spells, items and achievements that use them. An icon's file name or file ID, as "
        .. "Wowhead shows them (inv_misc_book_09, 133741), finds that icon."] = "Шукає іконки за назвами "
        .. "заклинань, предметів і досягнень, у яких вони є. Ім'я файлу іконки чи її ID, як їх показує Wowhead "
        .. "(inv_misc_book_09, 133741), знаходить саме цю іконку.",

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
    ["PvP talents active"] = "діють PvP-таланти",
    ["PvP talents not active"] = "PvP-таланти не діють",
    ["not at a house"] = "не біля будинку",
    ["on its plot"] = "на ділянці",
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
    ["with you now"] = "зараз з вами",
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
    ["Turns your action bar to that page: /changeactionbar 2."] =
        "Перемикає панель дій на цю сторінку: /changeactionbar 2.",
    ["Turns your action bar to one of two pages, the one it isn't on: /swapactionbar 1 2."] =
        "Перемикає панель дій на одну з двох сторінок, на ту, якої зараз немає: /swapactionbar 1 2.",
    ["Places a marker on the ground by its number, 1-8: /worldmarker [@cursor] 1 puts it under the mouse."] =
        "Ставить маркер на землю за його номером, 1-8: /worldmarker [@cursor] 1 ставить його під курсор.",
    ["Clears a marker on the ground by its number, or all of them: /clearworldmarker all."] =
        "Прибирає маркер із землі за його номером або всі: /clearworldmarker all.",
    ["Your pet casts that spell by itself from now on: /petautocaston Torment."] =
        "Відтепер улюбленець сам застосовує це заклинання: /petautocaston Torment.",
    ["Your pet no longer casts that spell by itself."] = "Улюбленець більше не застосовує це заклинання сам.",
    ["Your pet starts or stops casting that spell by itself: each press turns it the other way."] =
        "Улюбленець починає або перестає сам застосовувати це заклинання: кожне натискання перемикає.",
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
    ["Your PvP talents work here: in War Mode, a battleground or an arena."] =
        "Тут діють ваші PvP-таланти: у режимі війни, на полі бою чи на арені.",
    ["You are at a house, inside or on its plot. Or where you name: house:inside, house:plot, house:editor "
        .. "(its editor is open), house:neighborhood."] =
        "Ви біля будинку: у ньому чи на його ділянці. Або там, де вказано: house:inside, house:plot, house:editor "
        .. "(відкрито його редактор), house:neighborhood.",
    ["Your PvP talents don't work here."] = "Тут ваші PvP-таланти не діють.",
    ["You are not at a house, or not where you name."] = "Ви не біля будинку або не там, де вказано.",
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
    ["Channeling or not"] = "Під час потоку чи ні",
    ["Not while channeling it"] = "Не поки воно триває",
    ["Not while channeling"] = "Не під час потокового",
    ["While channeling"] = "Під час потокового",
    ["Channeling"] = "Потокові заклинання",
    ["A channeled spell (Drain Soul, Mind Flay) stops when you press another one. \"Not while channeling it\": pressed again, the macro doesn't start its spell over. \"Not while channeling\": the macro does nothing until any of them ends."] =
        "Потокове заклинання (Drain Soul, Mind Flay) зривається, коли натиснути інше. «Не поки воно триває»: "
        .. "повторне натискання не почне заклинання макросу спочатку. «Не під час потокового»: макрос нічого не "
        .. "робить, доки триває будь-яке з них.",
    ["In any form or none"] = "У будь-якій формі чи без",
    ["In no form"] = "Без форми",
    ["Anywhere"] = "Будь-де",
    ["On a mount"] = "Верхи",
    ["Not on a mount"] = "Не верхи",
    ["In flight"] = "У польоті",
    ["Not in flight"] = "Не в польоті",
    ["Where you can't fly"] = "Де літати не можна",
    ["Where you can skyride"] = "Де працює небесна їзда",
    ["Not in water"] = "Не у воді",
    ["Indoors"] = "У приміщенні",
    ["Outdoors"] = "Надворі",
    ["Resting, in a city or an inn"] = "На відпочинку, у місті чи таверні",
    ["Not resting"] = "Не на відпочинку",
    ["In a house or on its plot"] = "У будинку чи на його ділянці",
    ["In any specialization"] = "У будь-якій спеціалізації",
    ["In the primary specialization"] = "В основній спеціалізації",
    ["In the secondary specialization"] = "У додатковій спеціалізації",
    ["In specialization %s"] = "У спеціалізації %s",
    ["With any gear"] = "З будь-якою екіпіровкою",
    ["With %s equipped"] = "З вдягнутим %s",
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
    -- Macros from the spellbook
    ["The macro would be longer than %d characters."] = "Макрос вийде довшим за %d символів.",
    ["%s already has a spell on this key."] = "У макросі %s на цій клавіші вже є заклинання.",
    ["Join it to a spell that gets a macro of its own."] =
        "Приєднайте його до заклинання, яке отримує власний макрос.",
    ["From Spellbook"] = "З книги заклинань",
    ["Macros from the Spellbook"] = "Макроси з книги заклинань",
    ["Make macros for the spells in your spellbook, many at once. Pick the spells, where they go and what Shift, Ctrl "
        .. "or Alt do. Spells that have a macro already are left out. Next time, the spells you learned since and those "
        .. "whose macro you deleted are offered."] = "Макроси для заклинань із вашої книги, багато за раз. Оберіть заклинання, у кого вони "
        .. "летять і що роблять Shift, Ctrl чи Alt. Заклинання, які вже мають макрос, пропускаються. Наступного разу "
        .. "буде запропоновано те, що ви вивчили відтоді, і заклинання, чиї макроси ви видалили.",
    ["Check the spells to make macros for. A macro names the spell with no rank, so it always casts the highest rank "
        .. "you know. Point at a spell to see its macro."] = "Позначте заклинання, для яких зробити макроси. Макрос "
        .. "називає заклинання без рангу, тож завжди кастує найвищий ранг, який ви знаєте. Наведіть мишу на "
        .. "заклинання, щоб побачити його макрос.",
    ["Already in the macro \"%s\""] = "Уже є в макросі «%s»",
    ["You deleted its macro"] = "Ви видалили його макрос",
    ["Left out last time"] = "Пропущене минулого разу",
    ["new"] = "нове",
    ["Own macro"] = "Власний макрос",
    ["With %s"] = "Разом із %s",
    ["+ %s"] = "+ %s",
    ["Macro \"%s\":"] = "Макрос «%s»:",
    ["Attacks go to"] = "Атаки летять у",
    ["Helpful spells go to"] = "Корисні заклинання — у",
    ["The enemy under the mouse, else your target"] = "Ворога під мишею, інакше в ціль",
    ["The friend under the mouse, else your target"] = "Друга під мишею, інакше в ціль",
    ["Your focus, else your target"] = "Фокус, інакше в ціль",
    ["Start auto attack with each attack"] = "Вмикати автоатаку з кожною атакою",
    ["Stop your cast before an interrupt"] = "Зупиняти свій каст перед перериванням",
    ["Put them on the bars in place of the spells"] = "Поставити на панелі замість заклинань",
    ["A macro for your pet"] = "Макрос для улюбленця",
    ["No key"] = "Без клавіші",
    ["Nothing"] = "Нічого",
    ["Attack the enemy under the mouse first"] = "Спершу атакувати ворога під мишею",
    ["Macros: %d. Free slots: %d."] = "Макросів: %d. Вільних місць: %d.",
    ["Not enough room: leave some spells out, or join them to others on a key."] =
        "Не вистачає місця: зніміть галочки з кількох заклинань або приєднайте їх до інших на клавішу.",
    ["Create macros (%d)"] = "Створити макроси (%d)",
    ["macros made: %d; put on the action bars: %d"] = "створено макросів: %d; поставлено на панелі: %d",
    ["could not make the macro \"%s\" (the game said: %s)"] = "не вдалося створити макрос «%s» (гра відповіла: %s)",
    ["its text: %s"] = "його текст: %s",
    ["making %d macros..."] = "створюю макроси: %d...",
    ["Where this spell goes"] = "Куди летить це заклинання",
    ["\"—\" goes where the choice for all attacks or helpful spells says. Pick another to send only this spell "
        .. "elsewhere."] = "«—» — туди, куди вказано для всіх атак чи корисних заклинань. Оберіть інше, щоб лише це "
        .. "заклинання летіло деінде.",
    ["Spell"] = "Заклинання",
    ["Key"] = "Клавіша",
    ["Lower rank"] = "Нижчий ранг",
    ["Check a spell to make a macro for it. A spell with no check box ticked has a macro already, or you left it out "
        .. "before: you can still tick it."] = "Позначте заклинання, щоб зробити для нього макрос. Заклинання без "
        .. "галочки вже має макрос або ви пропустили його раніше. Його все одно можна позначити.",
    ["The key to hold for a spell joined to another macro, or for a lower rank."] =
        "Клавіша, яку треба тримати для заклинання, приєднаного до іншого макросу, або для нижчого рангу.",
    ["A lower rank of the spell, cast while you hold the key. It costs less mana: to heal a little, to put a cheap "
        .. "spell on an enemy for them to dispel, or to waste a warrior's Spell Reflection on it."] =
        "Нижчий ранг заклинання, який кастується, поки ви тримаєте клавішу. Він коштує менше мани: щоб підлікувати "
        .. "потроху, повісити на ворога дешеве заклинання, яке він розвіє, або витратити на нього Spell Reflection "
        .. "воїна.",
    ["\"Own macro\": the spell gets a macro of its own. \"With\" another spell: it goes into that spell's macro and "
        .. "is cast while you hold the key. This saves macro slots."] = "«Власний макрос»: заклинання отримує свій "
        .. "макрос. «Разом із» іншим заклинанням: воно йде в макрос того заклинання і кастується, поки ви тримаєте "
        .. "клавішу. Так економляться місця для макросів.",
    ["You know only one rank of this spell."] = "Ви знаєте лише один ранг цього заклинання.",
    ["From the spellbook"] = "З книги заклинань",
    ["\"From Spellbook\" makes macros for many spells of your spellbook at once. Tick the spells, and each gets a "
        .. "macro that names its spell with no rank: in the Classic clients it always casts the highest rank you know. "
        .. "Point at a spell to see its macro."] = "«З книги заклинань» робить макроси для багатьох заклинань із вашої "
        .. "книги за раз. Позначте заклинання, і кожне отримає макрос, який називає його без рангу: у Classic він "
        .. "завжди кастує найвищий ранг, який ви знаєте. Наведіть мишу на заклинання, щоб побачити його макрос.",
    ["Where the spells go: your target, the unit under the mouse or your focus. For all of them on the right; for one "
        .. "spell in its row, where \"—\" keeps the choice for all."] = "Куди летять заклинання: у вашу ціль, у того, "
        .. "хто під мишею, або у фокус. Для всіх — праворуч; для одного заклинання — у його рядку, де «—» лишає "
        .. "загальний вибір.",
    ["\"With\" another spell puts this one into that spell's macro, on the key you pick. This saves macro slots."] =
        "«Разом із» іншим заклинанням кладе це заклинання в макрос того, на вибрану клавішу. Так економляться місця "
        .. "для макросів.",
    ["A cheaper rank on a key: to heal a little, or to waste an enemy's dispel or a warrior's Spell Reflection."] =
        "Дешевший ранг на клавішу: щоб підлікувати потроху або змусити ворога витратити розвіювання чи Spell "
        .. "Reflection воїна.",
    ["Delete such a macro here, and its spell comes back onto its buttons, if the macro still casts it."] =
        "Видаліть такий макрос тут, і на його кнопки повернеться заклинання, якщо макрос досі його кастує.",
    ["Spells that some macro casts already are not ticked. Next time, only the spells you learned since are."] =
        "Заклинання, які вже кастує якийсь макрос, стоять без галочки. Наступного разу галочки стоятимуть лише на "
        .. "тих, що ви вивчили відтоді.",
    ["shortened by 146%%"] = "скорочено на 146%%",
    ["macro sets %s"] = "набори макросів: %s",
    ["\"%s\" is in this layer now: %s"] = "«%s» тепер у шарі: %s",
    ["no macro \"%s\" in this character's slots (macro sets on?)"] =
        "у слотах цього персонажа немає макросу «%s» (набори макросів увімкнено?)",
    ["%d macros wait behind the scenes: there is no free slot for them. Pick which to take in under "
        .. "\"Macro sets\""] = "макросів чекають за лаштунками: %d — для них немає вільних слотів. Які взяти в гру, "
        .. "оберіть у «Наборах макросів»",
    ["something went wrong, so MacroSense undid this change: your macros and sets are as they were. "
        .. "Please report the error"] = "щось пішло не так, тож MacroSense скасував цю зміну: ваші макроси й "
        .. "набори такі, як були. Будь ласка, повідомте про помилку",
    ["Class macros"] = "Класові",
    ["Primary"] = "Основна",
    ["Secondary"] = "Додаткова",
    ["This character's"] = "Цього персонажа",
    ["This specialization's"] = "Цієї спеціалізації",
    -- Macro sets
    ["Macro sets"] = "Набори макросів",
    ["More macros than 30 slots: each specialization gets macros of its own, and they come into the game with it, "
        .. "onto their buttons. Class macros are shared by all your characters of one class."] =
        "Більше макросів, ніж 30 слотів: у кожної спеціалізації свої макроси, і вони з'являються в грі разом із нею, "
        .. "на своїх кнопках. Класові макроси спільні для всіх ваших персонажів одного класу.",
    ["A character has only 30 macro slots. Macro sets make room: each specialization gets macros of its own. "
        .. "Choose a specialization, and its macros come into the game, onto their buttons, while the others' wait "
        .. "behind the scenes.\n\nClass macros are the same on all your characters of one class: change one, and "
        .. "the others get it too. This character's macros stay in every specialization.\n\nOnce turned on, all "
        .. "your character macros go into \"This character's\". Move them to a specialization or to the class in the "
        .. "list of macros: drag one there (hold Ctrl to copy it), or use \"...\" by its name. Or let \"Sort by "
        .. "spells\" do it. A backup of your macros is made first.\n\nSets made on another character of yours come over "
        .. "with \"Share\" > \"Import a code or text...\"."] =
        "У персонажа лише 30 слотів для макросів. Набори дають більше місця: у кожної спеціалізації свої макроси. "
        .. "Оберете спеціалізацію — її макроси з'являться в грі, на своїх кнопках, а макроси інших чекатимуть за "
        .. "лаштунками.\n\nКласові макроси однакові на всіх ваших персонажах одного класу: зміните один — інші "
        .. "отримають його теж. Макроси цього персонажа лишаються в кожній спеціалізації.\n\nЩойно ви ввімкнете "
        .. "набори, усі макроси персонажа потраплять у набір «Цього персонажа». Розкладіть їх у списку макросів по "
        .. "спеціалізаціях чи до класових: перетягніть макрос мишею (щоб скопіювати, тримайте Ctrl) або "
        .. "скористайтеся «...» біля його назви. Або доручіть це кнопці «Розкласти за заклинаннями». Спершу аддон "
        .. "зробить резервну копію ваших макросів.\n\nНабори, зроблені на іншому вашому персонажі, переносяться через "
        .. "«Обмін» > «Імпортувати код чи текст...».",
    ["Turn on macro sets"] = "Увімкнути набори макросів",
    ["MacroSense learns the spells of each specialization while you play it. Not yet: %s."] =
        "MacroSense дізнається заклинання кожної спеціалізації, поки ви нею граєте. Ще не знає: %s.",
    ["The same on all your characters of this class: what you change here reaches the others when they log in."] =
        "Однакові на всіх ваших персонажах цього класу: те, що ви тут зміните, інші отримають, щойно ви ними зайдете.",
    ["Behind the scenes"] = "За лаштунками",
    ["In the game"] = "У грі",
    ["Take in"] = "Взяти в гру",
    ["Put away"] = "За лаштунки",
    ["Keep behind the scenes"] = "Лишати за лаштунками",
    ["Come in with its specialization"] = "З'являтися разом зі спеціалізацією",
    ["Move to: %s"] = "Перенести в: %s",
    ["Copy to: %s"] = "Копіювати в: %s",
    ["Remove"] = "Прибрати",
    ["These take the character's macro slots: %d of %d."] = "Вони займають слоти макросів персонажа: %d з %d.",
    ["This specialization is not chosen now: its macros come into the game when you choose it."] =
        "Ця спеціалізація зараз не вибрана: її макроси вийдуть у гру, коли ви її виберете.",
    ["Character  %d/%d  +%d"] = "Персонаж  %d/%d  +%d",
    ["Kept by MacroSense, on no slot. Change any of them here. They come into the game with their specialization, "
        .. "with \"Take in\" in \"...\", or dragged into \"In the game\"."] =
        "Їх зберігає MacroSense, слотів вони не займають. Будь-який із них можна змінити тут. У гру вони виходять "
        .. "разом зі своєю спеціалізацією, через «Взяти в гру» в «...» або якщо перетягнути їх у «У грі».",
    ["The macros of the specialization chosen now."] = "Макроси спеціалізації, вибраної зараз.",
    ["Behind the scenes: not in the game now, and on no slot."] = "За лаштунками: зараз не в грі й не займає слота.",
    ["Works in every specialization: it could go to \"Class macros\""] =
        "Працює в усіх спеціалізаціях: його можна перенести в «Класові»",
    ["It can sort once it knows the spells of every specialization: choose each of them at least once."] =
        "Розкласти вийде, коли MacroSense знатиме заклинання всіх спеціалізацій: увімкніть кожну хоча б раз.",
    ["Sort by spells"] = "Розкласти за заклинаннями",
    ["MacroSense looks at the spells each macro casts, and offers to move it: one that works in one specialization "
        .. "only, into that one's set; a specialization's that works in all, to this character's. You see the moves "
        .. "before they are made."] =
        "MacroSense дивиться, які заклинання кастує кожен макрос, і пропонує його перенести: той, що працює лише в "
        .. "одній спеціалізації, — у її набір; макрос спеціалізації, що працює в усіх, — до макросів цього "
        .. "персонажа. Перед перенесенням ви побачите всі зміни.",
    ["Move these macros to where their spells are?\n\n%s"] =
        "Перенести ці макроси туди, де є їхні заклинання?\n\n%s",
    ["and %d more"] = "і ще %d",
    ["Not in this specialization: %s"] = "Немає в цій спеціалізації: %s",
    ["Works only in %s"] = "Працює лише в %s",
    ["the class macro \"%s\" waits off the slots: a macro of yours has this name"] =
        "класовий макрос «%s» за лаштунками: у вас уже є свій макрос із такою назвою",
    ["moved: %d"] = "перенесено: %d",
    ["nothing to move: each macro is where its spells are"] =
        "переносити нічого: кожен макрос там, де є його заклинання",
    -- The guide: macro sets
    ["A character has only 30 macro slots. Macro sets let MacroSense keep more macros than that: each "
        .. "specialization gets macros of its own, and only the ones you need now are in the game. Turn them on with "
        .. "\"Macro sets\". They are off until you do."] =
        "У персонажа лише 30 слотів для макросів. З наборами MacroSense зберігає більше: у кожної спеціалізації "
        .. "свої макроси, а в грі лише ті, що потрібні зараз. Увімкніть їх галочкою «Набори макросів». Доки ви "
        .. "цього не зробите, набори вимкнені.",
    ["Three kinds of sets"] = "Три види наборів",
    ["The same on all your characters of one class. Change one, and your other characters of that class get the "
        .. "change too. They are in the game in every specialization."] =
        "Однакові на всіх ваших персонажах одного класу. Зміните один — зміна дійде й до інших персонажів цього "
        .. "класу. Вони в грі в кожній спеціалізації.",
    ["This character's own. They are in the game in every specialization. When the sets are first turned on, all "
        .. "your character macros are here."] =
        "Макроси лише цього персонажа. Вони в грі в кожній спеціалізації. Коли ви вперше вмикаєте набори, сюди "
        .. "потрапляють усі макроси персонажа.",
    ["A specialization"] = "Спеціалізація",
    ["Its macros are in the game only while it is chosen. Choose another, and they wait behind the scenes, while "
        .. "that one's come into the game, onto the same buttons they had on your action bars."] =
        "Її макроси в грі, лише поки її вибрано. Оберете іншу — вони підуть за лаштунки, а в гру вийдуть макроси "
        .. "тієї, на ті самі кнопки панелей дій, де вони були.",
    ["In the game and behind the scenes"] = "У грі й за лаштунками",
    ["With the sets on, the list of character macros has two parts. \"In the game\" holds the macros in your slots "
        .. "right now: they are on your action bars and work. \"Behind the scenes\" holds the macros MacroSense keeps "
        .. "for you: they take no slot. You can open, change, make and delete them there like any other macro."] =
        "Коли набори ввімкнені, список макросів персонажа має дві частини. «У грі» — макроси, що зараз займають "
        .. "слоти: вони на ваших панелях дій і працюють. «За лаштунками» — макроси, які зберігає для вас "
        .. "MacroSense: слотів вони не займають. Їх так само можна відкривати, змінювати, створювати й видаляти.",
    ["Class macros are marked yellow, the specialization chosen now green, and all that is behind the scenes red. "
        .. "The groups open and close with a click."] =
        "Класові макроси позначені жовтим, вибрана зараз спеціалізація — зеленим, а все, що за лаштунками, — "
        .. "червоним. Групи розгортаються й згортаються клацанням.",
    ["What you can do with a macro"] = "Що можна зробити з макросом",
    ["Press \"...\" by a macro's name, or right-click it:"] =
        "Натисніть «...» біля назви макроса або клацніть по ньому правою кнопкою:",
    ["The macro leaves the game and waits behind the scenes, in its own set. Its slot is free for another."] =
        "Макрос виходить із гри й чекає за лаштунками у своєму наборі. Його слот звільняється для іншого.",
    ["The macro comes back into the game. It needs a free slot, and no other macro of the same name in the game."] =
        "Макрос повертається в гру. Для цього потрібен вільний слот, і в грі не має бути іншого макроса з такою "
        .. "самою назвою.",
    ["For a macro of a specialization not chosen now: it stays behind the scenes even when you choose that "
        .. "specialization, and its name is grey in the list. \"Come in with its specialization\" undoes it."] =
        "Для макроса спеціалізації, яку зараз не вибрано: він лишається за лаштунками, навіть коли ви її оберете, "
        .. "а його назва в списку сіра. «З'являтися разом зі спеціалізацією» це скасовує.",
    ["Kept behind the scenes: it doesn't come into the game when you choose this specialization."] =
        "Лишається за лаштунками: не з'явиться в грі, коли ви оберете цю спеціалізацію.",
    ["Move to"] = "Перенести в",
    ["The macro goes to another set and leaves this one. If it was in the game and the new set is in the game too, "
        .. "it stays where it is, on its buttons. Moved to a specialization not chosen now, it leaves the game until "
        .. "you choose it. If the set already has the very same macro (the same text), the two become one."] =
        "Макрос переходить в інший набір і зникає з цього. Якщо він був у грі й новий набір теж у грі, макрос "
        .. "лишається на місці, на своїх кнопках. Перенесений у спеціалізацію, яку зараз не вибрано, він виходить "
        .. "із гри, доки ви її не оберете. Якщо в наборі вже є точнісінько такий самий макрос (з тим самим "
        .. "текстом), вони стають одним.",
    ["Copy to"] = "Копіювати в",
    ["A copy goes to another set, and the macro itself stays as it is. From then on they are two separate macros: "
        .. "change or rename one, and the other stays as it was."] =
        "Копія йде в інший набір, а сам макрос лишається як був. Відтепер це два окремі макроси: зміните чи "
        .. "перейменуєте один — інший не зміниться.",
    ["The macro leaves its set and goes back to this character's. If this character's already has the very same "
        .. "macro, the two become one. If it has a different macro of the same name, nothing happens: rename one of "
        .. "them first."] =
        "Макрос іде зі свого набору й повертається до макросів цього персонажа. Якщо там уже є точнісінько такий "
        .. "самий макрос, вони стають одним. Якщо там є інший макрос із такою самою назвою, нічого не станеться: "
        .. "спершу перейменуйте один із них.",
    ["Dragging"] = "Перетягування",
    ["Drag"] = "Перетягнути",
    ["Drag a macro onto any part of the list to move it there. Onto \"Behind the scenes\", and it waits there. Onto "
        .. "\"In the game\", and it becomes this character's and comes into the game. Onto a group, and it goes to "
        .. "that set, in the game or behind the scenes, as that part of the list is."] =
        "Перетягніть макрос на будь-яку частину списку, і він переміститься туди. На «За лаштунками» — чекатиме "
        .. "там. На «У грі» — стане макросом цього персонажа й вийде в гру. На групу — перейде в її набір, у гру "
        .. "чи за лаштунки, залежно від того, в якій частині списку ця група.",
    ["Ctrl"] = "Ctrl",
    ["Hold Ctrl when you start dragging or when you let go, and the macro is copied instead of moved."] =
        "Затисніть Ctrl, коли починаєте тягнути або коли відпускаєте, і макрос скопіюється, а не переміститься.",
    ["Action bars"] = "Панелі дій",
    ["A macro in the game can still be dragged onto an action bar."] =
        "Макрос, що в грі, як і раніше можна перетягнути на панель дій.",
    ["Names"] = "Назви",
    ["One in the game"] = "Одна в грі",
    ["The game tells macros apart by their names, so only one macro of a name can be in the game at a time. A macro "
        .. "whose name is taken waits behind the scenes, and MacroSense says so in the chat."] =
        "Гра розрізняє макроси за назвами, тож у грі водночас може бути лише один макрос із певною назвою. Макрос, "
        .. "чию назву вже зайнято, чекає за лаштунками, і MacroSense пише про це в чаті.",
    ["In different sets"] = "У різних наборах",
    ["Each set may have a macro of the same name. Two specializations' come in each with its own specialization, "
        .. "onto its own buttons. If a class macro or one of this character's of that name is in the game, the "
        .. "specialization's waits."] =
        "У кожному наборі може бути макрос з однаковою назвою. Макроси двох спеціалізацій виходять у гру кожен "
        .. "зі своєю спеціалізацією, на свої кнопки. Якщо в грі є класовий макрос або макрос цього персонажа з "
        .. "такою назвою, макрос спеціалізації чекає.",
    ["Renaming"] = "Перейменування",
    ["Renaming or changing a macro changes only that one: its copies in other sets stay as they are."] =
        "Перейменування чи зміна макроса стосується лише його: копії в інших наборах лишаються як були.",
    ["Good to know"] = "Варто знати",
    ["No free slot"] = "Немає вільного слота",
    ["A macro that should come into the game but finds no free slot waits behind the scenes. Put another one away "
        .. "to make room. A new macro with no free slot (from \"New\", the wizard, a copy, the trash or \"From "
        .. "Spellbook\") is made behind the scenes, in this character's; MacroSense asks first, until you tell it not "
        .. "to. A general macro moved into the Character tab with no free slot goes behind the scenes the same way, "
        .. "off its buttons."] =
        "Макрос, який мав би вийти в гру, але не знайшов вільного слота, чекає за лаштунками. Заберіть за "
        .. "лаштунки інший, щоб звільнити місце. Новий макрос без вільного слота («Новий», майстер, копія, "
        .. "кошик чи «З книги заклинань») створюється за лаштунками, серед макросів цього персонажа; спершу "
        .. "MacroSense перепитає, доки ви не попросите більше не нагадувати. Загальний макрос, перенесений у "
        .. "вкладку «Персонаж», коли там немає вільного слота, так само йде за лаштунки й зникає зі своїх кнопок.",
    ["MacroSense looks at the spells each macro casts and offers to move it: one that works in one specialization "
        .. "only, to that one; a specialization's that works in all, to this character's. You see every move first. "
        .. "It works once MacroSense knows the spells of every specialization: choose each of them at least once."] =
        "MacroSense дивиться, які заклинання кастує кожен макрос, і пропонує його перенести: той, що працює лише "
        .. "в одній спеціалізації, — у неї; макрос спеціалізації, що працює в усіх, — до макросів цього "
        .. "персонажа. Спершу ви побачите всі зміни. Це запрацює, коли MacroSense знатиме заклинання всіх "
        .. "спеціалізацій: увімкніть кожну хоча б раз.",
    ["Deleted"] = "Видалені",
    ["A macro deleted behind the scenes goes to the trash, like any other."] =
        "Макрос, видалений за лаштунками, потрапляє в кошик, як і будь-який інший.",
    ["Turned off"] = "Вимкнення",
    ["A backup"] = "Резервна копія",
    ["Each time you turn the sets on, MacroSense first makes a backup of your macros."] =
        "Щоразу, коли ви вмикаєте набори, MacroSense спершу робить резервну копію ваших макросів.",
    ["How it works"] = "Як це працює",
    -- Macro sets: what each change says, with the rule it met
    ["\"%s\" waits behind the scenes: there is no free slot, a character has only 30. Put another macro behind the "
        .. "scenes, then take this one in."] =
        "«%s» чекає за лаштунками: вільного слота немає, у персонажа їх лише 30. Заберіть за лаштунки інший "
        .. "макрос, а тоді візьміть цей у гру.",
    ["\"%s\" waits behind the scenes: a macro of this name is in the game already, and the game tells macros apart "
        .. "by name. Rename one of them, or put the other one behind the scenes."] =
        "«%s» чекає за лаштунками: у грі вже є макрос із такою назвою, а гра розрізняє макроси за назвами. "
        .. "Перейменуйте один із них або заберіть інший за лаштунки.",
    ["There are two macros named \"%s\" in the game, and MacroSense tells macros apart by name. Rename one of them "
        .. "first."] = "У грі два макроси з назвою «%s», а MacroSense розрізняє макроси за назвами. Спершу "
        .. "перейменуйте один із них.",
    ["two macros in the game are named \"%s\": MacroSense tells macros apart by name, so it won't change the sets' "
        .. "macros until you rename one of them"] = "у грі два макроси з назвою «%s»: MacroSense розрізняє макроси за "
        .. "назвами, тож не змінюватиме макроси наборів, доки ви не перейменуєте один із них",
    ["no free slot for \"%s\": a character has only 30. Put another macro behind the scenes first."] =
        "для «%s» немає вільного слота: у персонажа їх лише 30. Спершу заберіть за лаштунки інший макрос.",
    ["\"%s\" can't come into the game: a macro of this name is there already, and only one of a name can be. Put "
        .. "that one behind the scenes, or rename one of them."] =
        "«%s» не може вийти в гру: там уже є макрос із такою назвою, а з однією назвою може бути лише один. "
        .. "Заберіть той за лаштунки або перейменуйте один із них.",
    ["\"%s\" has a macro named \"%s\" already: a set holds only one macro of a name. Rename one of them first."] =
        "у «%s» уже є макрос «%s»: у наборі може бути лише один макрос із певною назвою. Спершу перейменуйте "
        .. "один із них.",
    ["\"%s\" can't go back to \"This character's\": it has another macro of this name. If they had the same text, "
        .. "the two would be one. Rename one of them, or make them the same."] =
        "«%s» не може повернутися до «Цього персонажа»: там є інший макрос із такою назвою. Якби в них був "
        .. "однаковий текст, вони стали б одним макросом. Перейменуйте один із них або зробіть їх однаковими.",
    ["a copy goes into another set: drag \"%s\" with Ctrl onto another group."] =
        "копія йде в інший набір: перетягніть «%s» із затиснутою Ctrl на іншу групу.",
    ["\"%s\" is copied to \"%s\": now they are two macros of their own. Change or rename one, and the other stays "
        .. "as it is."] =
        "«%s» скопійовано в «%s»: тепер це два окремі макроси. Зміните чи перейменуєте один — інший лишиться "
        .. "як є.",
    ["\"%s\" will come into the game with its specialization: it isn't the one chosen now."] =
        "«%s» вийде в гру разом зі своєю спеціалізацією: зараз вибрано іншу.",
    ["\"%s\" stays behind the scenes, also when you choose its specialization. \"Come in with its specialization\" "
        .. "undoes it."] =
        "«%s» лишиться за лаштунками, навіть коли ви оберете його спеціалізацію. «З'являтися разом зі "
        .. "спеціалізацією» це скасовує.",
    ["\"%s\" is in \"%s\" now: it comes into the game when you choose that specialization."] =
        "«%s» тепер у «%s»: у гру він вийде, коли ви оберете цю спеціалізацію.",
    ["\"%s\" has a macro named \"%s\" already: a set holds only one macro of a name. Choose another name."] =
        "у «%s» уже є макрос «%s»: у наборі може бути лише один макрос із певною назвою. Оберіть іншу назву.",
    -- Macro sets: a macro dragged over a group
    ["Copy to \"%s\""] = "Копіювати в «%s»",
    ["Move to \"%s\""] = "Перенести в «%s»",
    ["Can't copy to \"%s\""] = "Не можна скопіювати в «%s»",
    ["Can't move to \"%s\""] = "Не можна перенести в «%s»",
    ["A macro of its own goes there; this one stays as it is. Let go of Ctrl to move it instead."] =
        "Туди піде окремий макрос, а цей лишиться як є. Відпустіть Ctrl, щоб перенести, а не копіювати.",
    ["It leaves its set and goes there. Hold Ctrl to copy it instead."] =
        "Макрос піде зі свого набору туди. Затисніть Ctrl, щоб скопіювати, а не переносити.",
    ["\"%s\" in \"%s\" was the very same macro: the two are one now."] =
        "«%s» у «%s» був точнісінько таким самим макросом: тепер це один макрос.",
    -- No free slot, macro sets on: made behind the scenes
    ["\"%s\" is made behind the scenes, in \"This character's\": there is no free slot. Put another macro behind the "
        .. "scenes, then take this one in."] =
        "«%s» створено за лаштунками, у «Цього персонажа»: вільного слота немає. Заберіть за лаштунки інший "
        .. "макрос, а тоді візьміть цей у гру.",
    ["Don't remind me again"] = "Більше не нагадувати",
    ["Make it behind the scenes"] = "Створити за лаштунками",
    ["Move it behind the scenes"] = "Перенести за лаштунки",
    ["All 30 slots are taken. MacroSense moves the macro behind the scenes, in \"This character's\", where it takes "
        .. "no slot, and off the action bars. To use it, put another macro behind the scenes and take it in."] =
        "Усі 30 слотів зайняті. MacroSense перенесе макрос за лаштунки, у «Цього персонажа», де він не займає "
        .. "слота, і прибере його з панелей дій. Щоб ним скористатися, заберіть за лаштунки інший макрос і візьміть "
        .. "цей у гру.",
    ["\"%s\" is moved behind the scenes, in \"This character's\": there is no free slot. Put another macro behind the "
        .. "scenes, then take this one in."] =
        "«%s» перенесено за лаштунки, у «Цього персонажа»: вільного слота немає. Заберіть за лаштунки інший "
        .. "макрос, а тоді візьміть цей у гру.",
    ["%d of the macros don't fit: all 30 slots are taken. MacroSense keeps them behind the scenes, in \"This "
        .. "character's\", where they take no slot. To use one, put another macro behind the scenes and take it in."] =
        "%d макросів не вміщаються: усі 30 слотів зайняті. MacroSense збереже їх за лаштунками, у «Цього "
        .. "персонажа», де вони не займають слотів. Щоб скористатися одним, заберіть за лаштунки інший макрос і "
        .. "візьміть цей у гру.",
    ["All 30 slots are taken. MacroSense keeps the new macro behind the scenes, in \"This character's\", where it "
        .. "takes no slot. To use it, put another macro behind the scenes and take it in."] =
        "Усі 30 слотів зайняті. MacroSense збереже новий макрос за лаштунками, у «Цього персонажа», де він не "
        .. "займає слота. Щоб ним скористатися, заберіть за лаштунки інший макрос і візьміть цей у гру.",
    ["Macros: %d. Free slots: %d. The rest go behind the scenes."] =
        "Макросів: %d. Вільних місць: %d. Решта піде за лаштунки.",
    ["%d macros are made behind the scenes, in \"This character's\": there is no free slot for them."] =
        "%d макросів створено за лаштунками, у «Цього персонажа»: вільних слотів для них немає.",
    -- Macro sets turned off: those behind the scenes come into the game
    ["Turn off macro sets?\n\n%s"] = "Вимкнути набори макросів?\n\n%s",
    ["Turn off"] = "Вимкнути",
    ["%d macros behind the scenes come into the game, so you have them all here. When you turn the sets on again, they "
        .. "go back where they were."] =
        "Макросів за лаштунками: %d. Вони вийдуть у гру, тож усі будуть під рукою. Коли ви знову ввімкнете набори, "
        .. "вони повернуться туди, де були.",
    ["%d don't fit (no free slot, or a macro of the same name is in the game already) and stay kept for later: %s."] =
        "%d не вміщаються (немає вільного слота або в грі вже є макрос із такою назвою) і лишаться збереженими на "
        .. "потім: %s.",
    ["Macro sets are on. Clear \"Macro sets\" to turn them off: the macros behind the scenes come into the game, and "
        .. "go back when you turn the sets on again."] =
        "Набори макросів увімкнено. Щоб вимкнути, зніміть галочку «Набори макросів»: макроси за лаштунками вийдуть у "
        .. "гру, а коли ви знову ввімкнете набори, повернуться назад.",
    ["Clear \"Macro sets\", and the macros behind the scenes come into the game, as many as there are free slots, so "
        .. "you have them all. If not all fit, you choose which come in. The sets are kept: turn them on again, and "
        .. "those macros go back where they were, with what you changed in them meanwhile."] =
        "Зніміть галочку «Набори макросів», і макроси за лаштунками вийдуть у гру, скільки вміститься у вільні "
        .. "слоти, тож усі будуть під рукою. Якщо всі не вміщаються, ви вибираєте, які саме. Набори збережуться: "
        .. "увімкнете їх знову — і ці макроси повернуться туди, де були, разом зі змінами, які ви тим часом у них "
        .. "зробили.",
    ["The other tab"] = "Інша вкладка",
    ["Any macro can be copied or moved from here to the other tab: a character macro to General, a general one to "
        .. "Character."] =
        "Звідси будь-який макрос можна скопіювати або перенести в іншу вкладку: макрос персонажа в «Загальні», "
        .. "загальний — у «Персонаж».",
    ["If something breaks"] = "Якщо щось зламалося",
    ["If a change breaks halfway, MacroSense undoes all of it: your macros, sets and buttons are as they were. It "
        .. "says so in the chat; please report the error then."] =
        "Якщо зміна зламається на півдорозі, MacroSense скасує її повністю: макроси, набори й кнопки будуть такі, "
        .. "як були. Він напише про це в чаті; тоді, будь ласка, повідомте про помилку.",
    ["Before level 10"] = "До 10 рівня",
    ["A character has no specialization yet: its macros are kept as \"No specialization yet\"."] =
        "У персонажа ще немає спеціалізації: його макроси зберігаються як «Ще без спеціалізації».",
    ["Primary and Secondary"] = "Основна і додаткова",
    ["In Classic Era, TBC, Mists of Pandaria and WoW Forever the sets follow your two talent groups: each has its "
        .. "own action bars there."] = "У Classic Era, TBC, Mists of Pandaria і WoW Forever набори йдуть за двома "
        .. "наборами талантів: там у кожного з них свої панелі дій.",
    ["Sets on another character"] = "Набори на іншому персонажі",
    ["Export sets"] = "Експорт наборів",
    ["\"Share\" > \"Export macro sets...\": check the sets you want and copy the code. \"Select all\" and \"Clear "
        .. "all\" check or clear them at once."] =
        "«Обмін» > «Експортувати набори макросів...»: позначте потрібні набори й скопіюйте код. «Вибрати все» і "
        .. "«Зняти все» позначають або знімають усі одразу.",
    ["Import sets"] = "Імпорт наборів",
    ["\"Share\" > \"Import a code or text...\": paste a code of sets, or choose another character of yours. Each "
        .. "set goes into its own; another class's sets go into this character's, and MacroSense warns you first. A "
        .. "name the set has already gets a number, the very same macro is skipped. They all come in behind the "
        .. "scenes: take in those you need."] =
        "«Обмін» > «Імпортувати код чи текст...»: вставте код наборів або виберіть іншого свого персонажа. Кожен "
        .. "набір іде у свій; набори іншого класу йдуть у «Цього персонажа», і MacroSense спершу про це попередить. "
        .. "Якщо в наборі вже є така назва, до неї додасться номер, а точнісінько такий самий макрос пропуститься. "
        .. "Усі вони приходять за лаштунки: візьміть у гру ті, що потрібні.",
    ["Your other characters"] = "Інші ваші персонажі",
    ["In the Character tab, their macros behind the scenes are listed too, with the name of their set."] =
        "У вкладці «Персонаж» видно і їхні макроси за лаштунками, з назвою набору.",
    ["Turn off macro sets"] = "Вимкнення наборів макросів",
    ["Not all the macros behind the scenes fit into the game: there are %d free slots. Choose which come in. The rest "
        .. "stay kept for later, and all go back where they were when you turn the sets on again."] =
        "Не всі макроси за лаштунками вміщаються в гру: вільних слотів %d. Оберіть, які вийдуть у гру. Решта "
        .. "лишиться збереженою на потім, а коли ви знову ввімкнете набори, усі повернуться туди, де були.",
    ["Chosen: %d of %d free slots"] = "Вибрано: %d із %d вільних слотів",
    ["%s  (%s; a macro of this name is in the game)"] = "%s  (%s; у грі вже є макрос із такою назвою)",
    ["Offer all again"] = "Запропонувати все знову",
    ["Forgets which spells you left out before and which macros you deleted: every spell with no macro is offered, "
        .. "checked, as the first time."] =
        "Забуває, які заклинання ви колись пропустили і які макроси видалили: кожне заклинання без макроса "
        .. "пропонується з галочкою, як уперше.",
}
