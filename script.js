const P_MAIN = 0
const P_FOREST__SOUTH = 1
const P_FOREST__NORTH = 2
function p_main (game, dom_parent) {
let e_list = [
(game) => 'enter the forest'
];
let h_list = [
(game) => ((e) => go_to(game, P_FOREST__NORTH))
];
let raw = '<p>you are outside of the forest.</p>\n\n<p><span id="w_0"></span>.</p>';
render_passage(game, dom_parent, raw, e_list, h_list);
}

function p_forest__south (game, dom_parent) {
let e_list = [
(game) => game.current_passage_index,
(game) => 'go north',
(game) => 'stay',
(game) => 'leave the forst'
];
let h_list = [
null,
(game) => ((e) => go_to(game, P_FOREST__NORTH)),
(game) => ((e) => go_to(game, P_FOREST__SOUTH)),
(game) => ((e) => go_to(game, P_MAIN))
];
let raw = '<p>\nyou are at the room in the south (<span id="w_0"></span>).\n</p>\n\n</p>\nyou can <span id="w_1"></span> or <span id="w_2"></span>. you can also <span id="w_3"></span>.\n</p>';
render_passage(game, dom_parent, raw, e_list, h_list);
}

function p_forest__north (game, dom_parent) {
let e_list = [
(game) => game.current_passage_index,
(game) => 'go south',
(game) => 'stay',
(game) => game.scream_counter+1,
(game) => game.scream_counter,
(game) => game.scream_counter,
(game) => 'scream(<span id="w_3"></span>)',
(game) => (game.scream_counter > 2 ?
    '<span id="w_4"></span>. that is a lot of screaming' :
    '<span id="w_5"></span>.'),
(game) => {
  if (game.scream_counter > 0) {
    return 'times you have screamed: <span id="w_7"></span>';
  } else {
    return '';
  }
  }
];
let h_list = [
null,
(game) => ((e) => go_to(game, P_FOREST__SOUTH)),
(game) => ((e) => go_to(game, P_FOREST__NORTH)),
null,
null,
null,
(game) => ((e) => {
  game.scream_counter += 1;
  alert('AAAA');
}),
null,
null
];
let raw = '<p>\nyou are at the room in the north (<span id="w_0"></span>).\n</p>\n\n<p>\nyou can <span id="w_1"></span> or <span id="w_2"></span>,\nor\n<span id="w_6"></span>.\n<span id="w_8"></span>\n</p>';
render_passage(game, dom_parent, raw, e_list, h_list);
}

let passage_list = [
p_main,
p_forest__south,
p_forest__north
];
