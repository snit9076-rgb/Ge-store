(function() {
    const root = document.getElementById('content');
    if (!root) return;

    const emojiMap = {
        smile: '😄', grin: '😁', joy: '😂', rofl: '🤣', sweat_smile: '😅', laughing: '😆',
        wink: '😉', blush: '😊', innocent: '😇', slight_smile: '🙂', upside_down: '🙃',
        yum: '😋', relieved: '😌', heart_eyes: '😍', kissing_heart: '😘', thinking: '🤔',
        neutral: '😐', expressionless: '😑', smirk: '😏', unamused: '😒', rolling_eyes: '🙄',
        disappointed: '😞', worried: '😟', confused: '😕', cry: '😢', sob: '😭',
        weary: '😩', tired: '😫', scream: '😱', angry: '😠', rage: '😡',
        mind_blown: '🤯', exploding_head: '🤯', cowboy: '🤠', nerd: '🤓', party: '🥳',
        sunglasses: '😎', cool: '😎', pleading: '🥺', hugging: '🤗', sleeping: '😴',
        poop: '💩', clown: '🤡', skull: '💀', ghost: '👻', robot: '🤖',
        wave: '👋', raised_hand: '✋', v: '✌️', victory: '✌️', ok: '👌',
        pinched_fingers: '🤌', call_me: '🤙', muscle: '💪', pray: '🙏', clap: '👏',
        thumbsup: '👍', '+1': '👍', thumbsdown: '👎', '-1': '👎', fist: '✊',
        punch: '👊', point_up: '☝️', point_down: '👇', point_left: '👈', point_right: '👉',
        raised_hands: '🙌', handshake: '🤝', writing_hand: '✍️', nail_care: '💅',
        eyes: '👀', ear: '👂', nose: '👃', tongue: '👅', brain: '🧠',
        anatomical_heart: '🫀', lungs: '🫁', heart: '❤️', orange_heart: '🧡', yellow_heart: '💛',
        green_heart: '💚', blue_heart: '💙', purple_heart: '💜', black_heart: '🖤',
        white_heart: '🤍', brown_heart: '🤎', broken_heart: '💔', heartpulse: '💗',
        two_hearts: '💕', revolving_hearts: '💞', sparkles: '✨', star: '⭐', stars: '🌟',
        dizzy: '💫', fire: '🔥', boom: '💥', collision: '💥', zap: '⚡', lightning: '⚡',
        snowflake: '❄️', sun: '☀️', moon: '🌙', cloud: '☁️', umbrella: '☔',
        rainbow: '🌈', ocean: '🌊', leaf: '🍃', seedling: '🌱', tree: '🌳',
        apple: '🍎', green_apple: '🍏', banana: '🍌', grapes: '🍇', strawberry: '🍓',
        peach: '🍑', cherries: '🍒', lemon: '🍋', avocado: '🥑', carrot: '🥕',
        pizza: '🍕', burger: '🍔', fries: '🍟', taco: '🌮', sushi: '🍣',
        ramen: '🍜', cake: '🍰', cookie: '🍪', chocolate: '🍫', coffee: '☕',
        tea: '🍵', beer: '🍺', wine: '🍷', cocktail: '🍸', champagne: '🍾',
        soccer: '⚽', basketball: '🏀', football: '🏈', baseball: '⚾', tennis: '🎾',
        trophy: '🏆', medal: '🏅', dart: '🎯', game_die: '🎲', joystick: '🕹️',
        art: '🎨', guitar: '🎸', piano: '🎹', microphone: '🎤', headphones: '🎧',
        movie: '🎬', camera: '📷', video_camera: '📹', tv: '📺', radio: '📻',
        rocket: '🚀', airplane: '✈️', car: '🚗', taxi: '🚕', bus: '🚌',
        train: '🚆', bicycle: '🚲', ship: '🚢', anchor: '⚓', fuelpump: '⛽',
        house: '🏠', office: '🏢', school: '🏫', hospital: '🏥', bank: '🏦',
        factory: '🏭', building: '🏗️', map: '🗺️', compass: '🧭', globe: '🌍',
        book: '📚', books: '📚', notebook: '📓', ledger: '📒', memo: '📝',
        pencil: '✏️', pen: '🖊️', paintbrush: '🖌️', ruler: '📏', scissors: '✂️',
        paperclip: '📎', pushpin: '📌', link: '🔗', tag: '🏷️', bookmark: '🔖',
        folder: '📁', open_file_folder: '📂', inbox: '📥', outbox: '📤',
        package: '📦', mailbox: '📫', envelope: '✉️', email: '📧', bell: '🔔',
        no_bell: '🔕', megaphone: '📣', loudspeaker: '📢', bulb: '💡', flashlight: '🔦',
        magnifying_glass: '🔍', mag: '🔍', lock: '🔒', unlock: '🔓', key: '🔑',
        hammer: '🔨', wrench: '🔧', nut_and_bolt: '🔩', gear: '⚙️', toolbox: '🧰',
        test_tube: '🧪', alembic: '⚗️', microscope: '🔬', telescope: '🔭',
        pill: '💊', syringe: '💉', warning: '⚠️', no_entry: '⛔', stop: '🛑',
        check: '✅', white_check_mark: '✅', x: '❌', cross_mark: '❌',
        heavy_plus_sign: '➕', heavy_minus_sign: '➖', question: '❓', grey_question: '❔',
        exclamation: '❗', grey_exclamation: '❕', info: 'ℹ️', recycling: '♻️',
        100: '💯', hundred: '💯', top: '🔝', new: '🆕', free: '🆓',
        soon: '🔜', on: '🔛', off: '🔚', cool_button: '🆒', id: '🆔',
        chart: '📈', chart_down: '📉', bar_chart: '📊', moneybag: '💰',
        credit_card: '💳', receipt: '🧾', briefcase: '💼', calendar: '📅',
        date: '📆', clock: '🕒', hourglass: '⏳', timer: '⏱️', target: '🎯',
        code: '💻', laptop: '💻', desktop: '🖥️', keyboard: '⌨️', mouse: '🖱️',
        printer: '🖨️', floppy_disk: '💾', minidisc: '💽', cd: '💿', dvd: '📀',
        satellite: '🛰️', wifi: '📶', signal: '📶', battery: '🔋', plug: '🔌',
        bug: '🐛', lady_beetle: '🐞', shield: '🛡️', unlock_button: '🔓', lock_button: '🔒'
    };

    const emojiRegex = /:([a-z0-9_+-]+):/g;
    const skipSelector = 'code,pre,a,script,style,textarea';

    const shouldSkip = (node) => {
        if (!node.parentElement) return true;
        return node.parentElement.closest(skipSelector);
    };

    const replaceEmoji = (node) => {
        const text = node.nodeValue;
        if (!text) return;
        emojiRegex.lastIndex = 0;
        let match;
        let lastIndex = 0;
        const fragment = document.createDocumentFragment();
        let replaced = false;

        while ((match = emojiRegex.exec(text)) !== null) {
            const start = match.index;
            if (start > lastIndex) {
                fragment.appendChild(document.createTextNode(text.slice(lastIndex, start)));
            }

            const key = match[1].toLowerCase();
            const emoji = emojiMap[key];
            fragment.appendChild(document.createTextNode(emoji ?? match[0]));
            lastIndex = emojiRegex.lastIndex;
            replaced = true;
        }

        if (!replaced) return;
        if (lastIndex < text.length) {
            fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
        }
        node.parentNode.replaceChild(fragment, node);
    };

    const walker = document.createTreeWalker(
        root,
        NodeFilter.SHOW_TEXT,
        {
            acceptNode: (node) => (shouldSkip(node) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT)
        }
    );

    const nodes = [];
    while (walker.nextNode()) {
        nodes.push(walker.currentNode);
    }
    nodes.forEach(replaceEmoji);
})();
