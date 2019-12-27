--[[ This code was originally used to generate this list. 
dev.first_tick(function(context)
    local base_pop = {} --:map<string, {serf: number, lord: number}>
    local regions = dev.region_list()
    io.open("sheildwall_output_base_pop.tsv","w+")
    for i = 0, regions:num_items() - 1 do
        local region = regions:item_at(i)
        local main_building = region:settlement():slot_list():item_at(0):building():chain()
        local serf = 100 --:number
        local lord = 25 --:number
        if region:is_province_capital() then
            serf = serf + 300
            lord = lord + 175
        end
        local main_building_additions = {
            ["vik_market"] = {600, 0},
            ["vik_farm"] = {100, 25},
            ["vik_hunting"] = {-50, 50},
            ["vik_orchard"] = {50, 25},
            ["vik_pasture"] = {50, 0},
            ["vik_pottery"] = {100, 0},
            ["vik_salt"] = {100, 0},
        }--:map<string, {number, number}>
        if main_building_additions[main_building] then
            serf = serf + main_building_additions[main_building][1]
            lord = lord + main_building_additions[main_building][2]
        end
        base_pop[region:name()] = {serf = serf, lord = lord}
    end

    for k, v in pairs(base_pop) do
        dev.export("base_pop", "\t[\""..k.."\"] = {serf = "..v.serf..", lord = "..v.lord.."},")
    end
end)
]]



local base_pop =  {
	["vik_reg_sconnin"] = {serf = 100, lord = 25},
	["vik_reg_bathanceaster"] = {serf = 50, lord = 75},
	["vik_reg_scrobbesburg"] = {serf = 100, lord = 25},
	["vik_reg_cair_segeint"] = {serf = 150, lord = 25},
	["vik_reg_hagustaldes"] = {serf = 100, lord = 25},
	["vik_reg_inis_cathaigh"] = {serf = 200, lord = 50},
	["vik_reg_tanet"] = {serf = 200, lord = 25},
	["vik_reg_cell_mor"] = {serf = 100, lord = 25},
	["vik_reg_brug"] = {serf = 200, lord = 50},
	["vik_reg_totanes"] = {serf = 100, lord = 25},
	["vik_reg_guldeford"] = {serf = 100, lord = 25},
	["vik_reg_dunholm"] = {serf = 100, lord = 25},
	["vik_reg_brideport"] = {serf = 200, lord = 25},
	["vik_reg_deoraby"] = {serf = 50, lord = 75},
	["vik_reg_cell_alaid"] = {serf = 100, lord = 25},
	["vik_reg_dun_nechtain"] = {serf = 50, lord = 75},
	["vik_reg_eofesham"] = {serf = 200, lord = 50},
	["vik_reg_balla"] = {serf = 200, lord = 50},
	["vik_reg_ioua"] = {serf = 400, lord = 200},
	["vik_reg_otergimele"] = {serf = 200, lord = 50},
	["vik_reg_ebbesham"] = {serf = 200, lord = 25},
	["vik_reg_cippanhamm"] = {serf = 400, lord = 200},
	["vik_reg_lonceaster"] = {serf = 50, lord = 75},
	["vik_reg_hripum"] = {serf = 100, lord = 25},
	["vik_reg_stutfall"] = {serf = 100, lord = 25},
	["vik_reg_tamworthige"] = {serf = 400, lord = 200},
	["vik_reg_druim_collachair"] = {serf = 150, lord = 25},
	["vik_reg_wigingamere"] = {serf = 100, lord = 25},
	["vik_reg_ferna"] = {serf = 200, lord = 50},
	["vik_reg_flichesburg"] = {serf = 200, lord = 25},
	["vik_reg_northwic"] = {serf = 1000, lord = 200},
	["vik_reg_thursa"] = {serf = 100, lord = 25},
	["vik_reg_dor"] = {serf = 100, lord = 25},
	["vik_reg_ros"] = {serf = 150, lord = 25},
	["vik_reg_loch_raich"] = {serf = 50, lord = 75},
	["vik_reg_latharna"] = {serf = 150, lord = 25},
	["vik_reg_casteltoun"] = {serf = 400, lord = 200},
	["vik_reg_lunden"] = {serf = 1000, lord = 200},
	["vik_reg_lann_afan"] = {serf = 200, lord = 50},
	["vik_reg_eidenburg"] = {serf = 400, lord = 200},
	["vik_reg_alclyt"] = {serf = 100, lord = 25},
	["vik_reg_ros_maircind"] = {serf = 50, lord = 75},
	["vik_reg_bornais"] = {serf = 400, lord = 200},
	["vik_reg_buccingahamm"] = {serf = 200, lord = 25},
	["vik_reg_cell_maic_aeda"] = {serf = 150, lord = 25},
	["vik_reg_staefford"] = {serf = 200, lord = 50},
	["vik_reg_glastingburi"] = {serf = 100, lord = 25},
	["vik_reg_suthhamtun"] = {serf = 200, lord = 50},
	["vik_reg_snotingaham"] = {serf = 400, lord = 200},
	["vik_reg_northhamtun"] = {serf = 400, lord = 200},
	["vik_reg_hereford"] = {serf = 50, lord = 75},
	["vik_reg_ligeraceaster"] = {serf = 200, lord = 50},
	["vik_reg_wiltun"] = {serf = 200, lord = 25},
	["vik_reg_rudglann"] = {serf = 100, lord = 25},
	["vik_reg_ros_ailithir"] = {serf = 100, lord = 25},
	["vik_reg_theodford"] = {serf = 200, lord = 50},
	["vik_reg_liwtune"] = {serf = 150, lord = 25},
	["vik_reg_menevia"] = {serf = 100, lord = 25},
	["vik_reg_gipeswic"] = {serf = 200, lord = 25},
	["vik_reg_stoc"] = {serf = 50, lord = 75},
	["vik_reg_coinnire"] = {serf = 200, lord = 25},
	["vik_reg_cathair_domnaill"] = {serf = 200, lord = 25},
	["vik_reg_cnodba"] = {serf = 200, lord = 50},
	["vik_reg_rendlesham"] = {serf = 400, lord = 200},
	["vik_reg_dun_att"] = {serf = 400, lord = 200},
	["vik_reg_dun_cailden"] = {serf = 400, lord = 200},
	["vik_reg_dacor"] = {serf = 100, lord = 25},
	["vik_reg_inis_faithlenn"] = {serf = 400, lord = 200},
	["vik_reg_rath_cruachan"] = {serf = 400, lord = 200},
	["vik_reg_coldingaham"] = {serf = 50, lord = 75},
	["vik_reg_sancte_albanes"] = {serf = 200, lord = 50},
	["vik_reg_wigracestre"] = {serf = 100, lord = 25},
	["vik_reg_gyruum"] = {serf = 150, lord = 25},
	["vik_reg_nedd"] = {serf = 200, lord = 50},
	["vik_reg_heslerton"] = {serf = 100, lord = 25},
	["vik_reg_rucestr"] = {serf = 50, lord = 75},
	["vik_reg_werham"] = {serf = 1000, lord = 200},
	["vik_reg_tuaim"] = {serf = 200, lord = 25},
	["vik_reg_seolesigge"] = {serf = 400, lord = 200},
	["vik_reg_middeherst"] = {serf = 50, lord = 75},
	["vik_reg_latharn"] = {serf = 100, lord = 25},
	["vik_reg_sancte_germanes"] = {serf = 200, lord = 50},
	["vik_reg_sancte_eadmundes"] = {serf = 100, lord = 25},
	["vik_reg_carleol"] = {serf = 1000, lord = 200},
	["vik_reg_wintanceaster"] = {serf = 400, lord = 200},
	["vik_reg_dyflin"] = {serf = 400, lord = 200},
	["vik_reg_lis_mor"] = {serf = 100, lord = 25},
	["vik_reg_bodmine"] = {serf = 100, lord = 25},
	["vik_reg_mathrafal"] = {serf = 400, lord = 200},
	["vik_reg_cetretha"] = {serf = 400, lord = 200},
	["vik_reg_tintagol"] = {serf = 400, lord = 200},
	["vik_reg_laewe"] = {serf = 50, lord = 75},
	["vik_reg_earmutha"] = {serf = 100, lord = 25},
	["vik_reg_rinnin"] = {serf = 200, lord = 50},
	["vik_reg_licetfelda"] = {serf = 200, lord = 25},
	["vik_reg_aberteifi"] = {serf = 400, lord = 200},
	["vik_reg_grantabrycg"] = {serf = 1000, lord = 200},
	["vik_reg_gleawceaster"] = {serf = 1000, lord = 200},
	["vik_reg_rofeceaster"] = {serf = 150, lord = 50},
	["vik_reg_herutford"] = {serf = 50, lord = 75},
	["vik_reg_cell_cainning"] = {serf = 50, lord = 75},
	["vik_reg_wiht"] = {serf = 200, lord = 50},
	["vik_reg_aelmham"] = {serf = 100, lord = 25},
	["vik_reg_ros_cuissine"] = {serf = 100, lord = 25},
	["vik_reg_lann_ildut"] = {serf = 50, lord = 75},
	["vik_reg_dun_patraic"] = {serf = 400, lord = 200},
	["vik_reg_cherchebi"] = {serf = 150, lord = 25},
	["vik_reg_caisil"] = {serf = 400, lord = 200},
	["vik_reg_elig"] = {serf = 200, lord = 25},
	["vik_reg_gleann_da_loch"] = {serf = 50, lord = 75},
	["vik_reg_rath_luraig"] = {serf = 100, lord = 25},
	["vik_reg_clocher"] = {serf = 150, lord = 25},
	["vik_reg_dun_eachainn"] = {serf = 200, lord = 50},
	["vik_reg_stornochway"] = {serf = 200, lord = 25},
	["vik_reg_guvan"] = {serf = 400, lord = 200},
	["vik_reg_an_tinbhear_mor"] = {serf = 150, lord = 25},
	["vik_reg_cell_daltain"] = {serf = 100, lord = 25},
	["vik_reg_basengas"] = {serf = 100, lord = 25},
	["vik_reg_aebburcurnig"] = {serf = 200, lord = 50},
	["vik_reg_cridiatune"] = {serf = 50, lord = 75},
	["vik_reg_haestingas"] = {serf = 400, lord = 200},
	["vik_reg_colneceaster"] = {serf = 400, lord = 200},
	["vik_reg_waerincwicum"] = {serf = 400, lord = 200},
	["vik_reg_haverfordia"] = {serf = 150, lord = 25},
	["vik_reg_ard_fert"] = {serf = 100, lord = 25},
	["vik_reg_dofere"] = {serf = 200, lord = 50},
	["vik_reg_ard_mor"] = {serf = 100, lord = 25},
	["vik_reg_tuam_greine"] = {serf = 150, lord = 25},
	["vik_reg_dun_blann"] = {serf = 50, lord = 75},
	["vik_reg_airchardan"] = {serf = 400, lord = 200},
	["vik_reg_cantwaraburg"] = {serf = 400, lord = 200},
	["vik_reg_mameceaster"] = {serf = 400, lord = 200},
	["vik_reg_dun_foither"] = {serf = 400, lord = 200},
	["vik_reg_din_prys"] = {serf = 50, lord = 75},
	["vik_reg_dun_na_ngall"] = {serf = 100, lord = 25},
	["vik_reg_rocheberie"] = {serf = 150, lord = 50},
	["vik_reg_dun_aberte"] = {serf = 200, lord = 25},
	["vik_reg_cairlinn"] = {serf = 50, lord = 75},
	["vik_reg_veisafjordr"] = {serf = 400, lord = 200},
	["vik_reg_wyrcesuuyrthe"] = {serf = 150, lord = 25},
	["vik_reg_poclintun"] = {serf = 200, lord = 50},
	["vik_reg_dugannu"] = {serf = 100, lord = 25},
	["vik_reg_sancte_ye"] = {serf = 150, lord = 25},
	["vik_reg_lindcylne"] = {serf = 400, lord = 200},
	["vik_reg_hwitan_aerne"] = {serf = 100, lord = 25},
	["vik_reg_oxnaforda"] = {serf = 150, lord = 50},
	["vik_reg_axanbrycg"] = {serf = 100, lord = 25},
	["vik_reg_ethandun"] = {serf = 200, lord = 50},
	["vik_reg_lann_dewi"] = {serf = 100, lord = 25},
	["vik_reg_domuc"] = {serf = 200, lord = 50},
	["vik_reg_eoferwic"] = {serf = 1000, lord = 200},
	["vik_reg_waecet"] = {serf = 150, lord = 25},
	["vik_reg_tureceseig"] = {serf = 200, lord = 50},
	["vik_reg_loch_gabhair"] = {serf = 100, lord = 25},
	["vik_reg_corcach"] = {serf = 400, lord = 200},
	["vik_reg_oswaldestroe"] = {serf = 200, lord = 50},
	["vik_reg_cluain"] = {serf = 100, lord = 25},
	["vik_reg_aethelingaeg"] = {serf = 400, lord = 200},
	["vik_reg_porteceaster"] = {serf = 200, lord = 25},
	["vik_reg_celmeresfort"] = {serf = 200, lord = 50},
	["vik_reg_cluain_eoais"] = {serf = 200, lord = 25},
	["vik_reg_na_seciri"] = {serf = 150, lord = 25},
	["vik_reg_sreth_belin"] = {serf = 100, lord = 25},
	["vik_reg_vedrafjordr"] = {serf = 400, lord = 200},
	["vik_reg_cenn_rigmonid"] = {serf = 50, lord = 75},
	["vik_reg_nas"] = {serf = 400, lord = 200},
	["vik_reg_lude"] = {serf = 200, lord = 25},
	["vik_reg_cissanbyrig"] = {serf = 100, lord = 25},
	["vik_reg_sceaftesburg"] = {serf = 200, lord = 50},
	["vik_reg_ceaster"] = {serf = 1000, lord = 200},
	["vik_reg_torfness"] = {serf = 150, lord = 25},
	["vik_reg_cluain_mor"] = {serf = 100, lord = 25},
	["vik_reg_achadh_bo"] = {serf = 400, lord = 200},
	["vik_reg_exanceaster"] = {serf = 1000, lord = 200},
	["vik_reg_abberdeon"] = {serf = 100, lord = 25},
	["vik_reg_huntandun"] = {serf = 150, lord = 25},
	["vik_reg_inber_nise"] = {serf = 100, lord = 25},
	["vik_reg_beoferlic"] = {serf = 100, lord = 25},
	["vik_reg_ard_sratha"] = {serf = 200, lord = 50},
	["vik_reg_steanford"] = {serf = 1000, lord = 200},
	["vik_reg_tor_in_duine"] = {serf = 400, lord = 200},
	["vik_reg_aporcrosan"] = {serf = 100, lord = 25},
	["vik_reg_bedanford"] = {serf = 200, lord = 50},
	["vik_reg_blascona"] = {serf = 400, lord = 200},
	["vik_reg_staeningum"] = {serf = 200, lord = 50},
	["vik_reg_aberffro"] = {serf = 400, lord = 200},
	["vik_reg_lann_idloes"] = {serf = 100, lord = 25},
	["vik_reg_dun_domnaill"] = {serf = 200, lord = 50},
	["vik_reg_drayton"] = {serf = 200, lord = 25},
	["vik_reg_alt_clut"] = {serf = 200, lord = 25},
	["vik_reg_dun_beccan"] = {serf = 100, lord = 25},
	["vik_reg_dinefwr"] = {serf = 400, lord = 200},
	["vik_reg_inis_patraic"] = {serf = 150, lord = 25},
	["vik_reg_grianan_aileach"] = {serf = 400, lord = 200},
	["vik_reg_dun_sebuirgi"] = {serf = 400, lord = 200},
	["vik_reg_lann_cors"] = {serf = 200, lord = 50},
	["vik_reg_cathair_commain"] = {serf = 400, lord = 200},
	["vik_reg_maeldune"] = {serf = 200, lord = 25},
	["vik_reg_forais"] = {serf = 200, lord = 25},
	["vik_reg_ardach"] = {serf = 100, lord = 25},
	["vik_reg_linns"] = {serf = 200, lord = 25},
	["vik_reg_mailros"] = {serf = 150, lord = 25},
	["vik_reg_dynbaer"] = {serf = 200, lord = 25},
	["vik_reg_dun_ollaig"] = {serf = 50, lord = 75},
	["vik_reg_scoan"] = {serf = 400, lord = 200},
	["vik_reg_cirenceaster"] = {serf = 100, lord = 25},
	["vik_reg_cair_mirddin"] = {serf = 150, lord = 50},
	["vik_reg_bebbanburg"] = {serf = 400, lord = 200},
	["vik_reg_druim_da_ethiar"] = {serf = 400, lord = 200},
	["vik_reg_cluain_iraird"] = {serf = 150, lord = 25},
	["vik_reg_dun_duirn"] = {serf = 100, lord = 25},
	["vik_reg_doreceaster"] = {serf = 400, lord = 200},
	["vik_reg_dinas_powis"] = {serf = 100, lord = 25},
	["vik_reg_dear"] = {serf = 200, lord = 50},
	["vik_reg_scireburnan"] = {serf = 150, lord = 50},
	["vik_reg_saigher"] = {serf = 150, lord = 25},
	["vik_reg_tilaburg"] = {serf = 200, lord = 25},
	["vik_reg_cair_gwent"] = {serf = 1000, lord = 200},
	["vik_reg_doneceaster"] = {serf = 200, lord = 50},
	["vik_reg_brechin"] = {serf = 50, lord = 75},
	["vik_reg_ard_macha"] = {serf = 400, lord = 200},
	["vik_reg_loidis"] = {serf = 1000, lord = 200},
	["vik_reg_hlymrekr"] = {serf = 400, lord = 200},
	["vik_reg_imblech_ibair"] = {serf = 150, lord = 25},
	["vik_reg_cluain_mac_nois"] = {serf = 400, lord = 200},
	["vik_reg_pefenesea"] = {serf = 100, lord = 25},
	["vik_reg_moige_bile"] = {serf = 100, lord = 25},
	["vik_reg_cenannas"] = {serf = 150, lord = 25},
	["vik_reg_lann_padarn"] = {serf = 100, lord = 25}
} --:map<string, {serf: number, lord: number}>

return base_pop