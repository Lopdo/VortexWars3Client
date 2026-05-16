return {
    ["2p"] = {
        desc = "Two players",
        cmds = {
            "godot Test/test_scene.tscn -- -p=lopdo -m=test -a=cm -pc=2",
            "godot Test/test_scene.tscn -- -p=lopdo2 -m=test -a=jm",
        },
    },
    ["2pl"] = {
        desc = "Two players in lobby",
        cmds = {
            "godot Test/test_scene.tscn -- -p=lopdo -m=test -a=cm -pc=2 -lobby=true",
            "godot Test/test_scene.tscn -- -p=lopdo2 -m=test -a=jm -lobby=true",
        },
    },
    ["3players"] = {
        desc = "Three players",
        cmds = {
            "godot Test/test_scene.tscn -- -p=lopdo -m=test -a=cm -pc=3",
            "godot Test/test_scene.tscn -- -p=player2 -m=test -a=jm",
            "godot Test/test_scene.tscn -- -p=player3 -m=test -a=jm",
        },
    },
}
