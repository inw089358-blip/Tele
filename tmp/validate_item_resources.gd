extends SceneTree

const ITEM_IDS = [
"item_bible_old","item_dagger_rusty","item_lantern_apprentice","item_herb_dry","item_mirror_crude","item_bullet_lead","item_whetstone_heavy","item_coin_broken","item_rabbit_foot","item_feather_light","item_tarot_fragment","item_lens_shard","item_bandage_bloody","item_alchemist_coin","item_shield_wood","item_beads_meditation","item_potion_strange","item_bottle_empty","item_candle_ritual","item_boots_iron","item_pope_robe","item_magician_poker","item_chariot_wheel","item_priestess_mercy","item_hermit_candle","item_piggy_bank","item_merchant_scale","item_revenge_arrow","item_cursed_eye","item_star_dust","item_stake_tough","item_razor_sharp","item_telescope","item_watch_magnetic","item_crown_thorn","item_death_scythe","item_wheel_fortune","item_inquisitor_chain","item_temperance_sacrament","item_demon_contract","item_alchemist_crucible","item_moon_veil","item_justice_guillotine","item_world_tree_sapling","item_glutton_greed","item_emperor_throne","item_astronomy_orb","item_fool_pocket","item_star_source","item_world_omni"
]

func _initialize() -> void:
    var missing := []
    var failed := []
    for item_id in ITEM_IDS:
        var path := "res://sprite/items/%s.png" % item_id
        if not ResourceLoader.exists(path):
            missing.append(path)
            continue
        var tex: Texture2D = load(path)
        if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
            failed.append(path)
    print("resource_exists_ok=%d" % (ITEM_IDS.size() - missing.size()))
    print("resource_load_ok=%d" % (ITEM_IDS.size() - failed.size()))
    print("missing_count=%d" % missing.size())
    print("failed_count=%d" % failed.size())
    if missing.size() > 0:
        print(str(missing))
    if failed.size() > 0:
        print(str(failed))
    quit()
