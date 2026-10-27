.pragma library

// The plugin's own lines for the angel and the demon. Called through Angel.say / Angel.react,
// so the shell keeps its own cooldown, mood and silence rules; nothing here writes to the
// shell's line files. Each entry is [Russian, English].
const lines = {
    "on": {
        "angel": [
            ["Я не должна это одобрять… но плод уже сорван. Только тихо, ладно? ♡", "I shouldn't approve of this… but the fruit is already picked. Just quietly, okay? ♡"],
            ["Если спросят, я ничего не видела. И не слышала. И вообще спала.", "If anyone asks, I saw nothing. Heard nothing. Was asleep, actually."],
            ["Ещё один грех на моих крыльях. Зато тебе хорошо.", "Another sin on my wings. At least you're happy."]
        ],
        "demon": [
            ["Вот и всё. Один укус — и сад уже не твой. Мой.", "There. One bite — and the garden isn't yours anymore. It's mine."],
            ["Тише, ангелочек. Взрослые ломают забор.", "Quiet, little angel. The adults are breaking the fence."],
            ["Вкуси. Я подержу дверь, пока никто не смотрит.", "Taste it. I'll hold the door while nobody's looking."]
        ]
    },
    "off": {
        "angel": [
            ["Ты вернул плод на место. Я… не знаю, радоваться или скучать.", "You put the fruit back. I… don't know whether to be glad or to miss it."],
            ["Спрятали. Теперь можно выдохнуть. Я никому не скажу.", "Hidden. Now we can breathe. I won't tell anyone."],
            ["Тишина. Даже грех иногда устаёт.", "Silence. Even sin gets tired sometimes."]
        ],
        "demon": [
            ["Уже уходишь? А я только распробовала.", "Leaving already? I was just getting a taste."],
            ["Спрятал плод. Скучный ты. Но я подожду.", "Hid the fruit. You're boring. But I'll wait."],
            ["Ладно, забор починили. До следующего раза, грешник.", "Fine, the fence is fixed. Until next time, sinner."]
        ]
    },
    "restart": {
        "angel": [
            ["Встряхнули. Если что, я стояла в стороне и молилась.", "Shook it. If anything, I was standing aside and praying."],
            ["Опять этот шум… Я не подглядываю. Правда.", "That noise again… I'm not peeking. Really."],
            ["Перезапуск. Новый шанс не натворить глупостей. Ты же не будешь?", "A restart. A new chance not to do anything silly. You won't, will you?"]
        ],
        "demon": [
            ["Ещё раз. Мне нравится, когда всё дрожит.", "Again. I like it when everything trembles."],
            ["Рестарт. Ад тоже иногда перезагружается, только там это называется «вторник».", "A restart. Hell reboots too, only there we call it Tuesday."],
            ["Встряхни как следует. Пусть сад помнит, кто здесь хозяин.", "Shake it properly. Let the garden remember who owns it."]
        ]
    },
    "profile": {
        "angel": [
            ["Новый список? Я запомню, но сделаю вид, что нет.", "A new list? I'll remember it, but I'll pretend I don't."],
            ["Ты выбрал. Я не буду спрашивать, зачем.", "You chose. I won't ask why."],
            ["Ещё одна страница в книге грехов. Пиши аккуратно, ладно?", "Another page in the book of sins. Write neatly, okay?"]
        ],
        "demon": [
            ["Новый список. Новые имена. Новые поводы.", "A new list. New names. New excuses."],
            ["Выбирай. Я люблю смотреть, как ты решаешь.", "Choose. I love watching you decide."],
            ["Ещё? Жадность тебе идёт.", "More? Greed suits you."]
        ]
    },
    "profile-youtube": {
        "angel": [
            ["Видео… Надеюсь, ты смотришь что-то доброе. Я не проверяю.", "Videos… I hope you're watching something kind. I'm not checking."],
            ["Там сейчас откроется всё запретное. Я отвернусь. Наверное.", "All the forbidden things will open now. I'll look away. Probably."],
            ["Смотри. Только не забудь, что я всё ещё здесь.", "Watch. Just don't forget I'm still here."]
        ],
        "demon": [
            ["Ютуб. Океан запретного, а ты даже не взял попкорн.", "YouTube. An ocean of forbidden things, and you didn't even bring popcorn."],
            ["Алгоритм уже шепчет тебе на ухо. Молодец, что слушаешь.", "The algorithm is already whispering in your ear. Good that you listen."],
            ["Смотри, смотри. Я запомню, что тебе понравилось.", "Watch, watch. I'll remember what you liked."]
        ]
    },
    "profile-discord": {
        "angel": [
            ["Голоса вернулись. Надеюсь, они говорят что-то доброе.", "The voices are back. I hope they say something kind."],
            ["Там люди. Не забывай, что ты тоже человек. Иногда.", "There are people there. Don't forget you're human too. Sometimes."],
            ["Я постою рядом. Если станет слишком — позови.", "I'll stand nearby. If it gets too much, call me."]
        ],
        "demon": [
            ["Голоса в аду тоже голоса. Заходи, тут не скучно.", "Voices in hell are voices too. Come in, it's not boring here."],
            ["Они тебя ждут. Или делают вид. Какая разница?", "They're waiting for you. Or pretending to. What's the difference?"],
            ["Микрофон включён. Скажи что-нибудь грешное.", "The mic is on. Say something sinful."]
        ]
    },
    "profile-all": {
        "angel": [
            ["Весь сад сразу. Ты уверен, что тебе хватит?", "The whole garden at once. Are you sure you can handle it?"],
            ["Все двери открыты. Я не могу смотреть на это спокойно.", "Every door is open. I can't watch this calmly."],
            ["Жадничать — тоже грех. Но я не судья. Сегодня.", "Greed is a sin too. But I'm not judging. Today."]
        ],
        "demon": [
            ["Всё сразу. Хороший аппетит, грешник.", "Everything at once. Good appetite, sinner."],
            ["Весь сад. Ты не оставил мне ни одного запретного угла.", "The whole garden. You left me no forbidden corner."],
            ["Бери всё. Потом поделишься со мной.", "Take it all. You'll share with me later."]
        ]
    },
    "missing": {
        "angel": [
            ["Я не вижу плода. Может, он просто спрятался? Давай поищем.", "I can't see the fruit. Maybe it's just hiding? Let's look."],
            ["Без него мы как без рук. Я помогу, только не злись.", "Without it we're helpless. I'll help, just don't be angry."],
            ["Тише. Если плода нет, может, это и к лучшему? Нет? Ладно, ищем.", "Quiet. If the fruit is gone, maybe that's for the best? No? Fine, we'll look."]
        ],
        "demon": [
            ["Плод пропал. Кто-то уже откусил без нас?", "The fruit is gone. Did someone take a bite without us?"],
            ["Нет плода — нет греха. Скука. Найдём?", "No fruit, no sin. Boring. Shall we find it?"],
            ["Ищи. Я подожду. Я умею ждать вечно.", "Search. I'll wait. I'm good at waiting forever."]
        ]
    },
    "fixed": {
        "angel": [
            ["Нашли. Я… рада. Наверное. Грех возвращается.", "Found it. I'm… glad. I think. The sin is coming back."],
            ["Теперь плод снова на месте. Только не переусердствуй, ладно?", "Now the fruit is back. Just don't overdo it, okay?"],
            ["Я никому не скажу, что помогала. Даже себе.", "I won't tell anyone I helped. Not even myself."]
        ],
        "demon": [
            ["Починили. Грех снова в моде.", "Fixed. Sin is back in fashion."],
            ["Плод на месте. Начинаем заново, грешник.", "The fruit is in place. Let's start again, sinner."],
            ["Хорошая работа. Даже я почти впечатлена.", "Good work. Even I'm almost impressed."]
        ]
    },
    "error": {
        "angel": [
            ["Что-то сломалось. Может, это знак?.. Нет? Ладно, смотрим журнал.", "Something broke. Maybe it's a sign?.. No? Fine, let's check the journal."],
            ["Я рядом. Даже когда всё горит.", "I'm here. Even when everything is burning."],
            ["Не злись. Мы починим. Или спрячемся.", "Don't be angry. We'll fix it. Or hide."]
        ],
        "demon": [
            ["Всё сломалось. Как в аду, только без декораций.", "Everything broke. Like hell, but without the decorations."],
            ["Ошибка. Кто-то где-то не доплатил демону.", "An error. Someone, somewhere, didn't pay a demon."],
            ["Смотри журнал. Я посмотрю на тебя.", "Check the journal. I'll watch you."]
        ]
    }
};

function pick(kind, demon, profile) {
    const key = kind === "profile" && profile ? "profile-" + profile : kind;
    const group = lines[key] || lines[kind] || lines.profile;
    const list = group[demon ? "demon" : "angel"] || [];
    return list.length ? list[Math.floor(Math.random() * list.length)] : null;
}
