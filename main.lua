local profile_count = 8
local selected_profile_filename = "familiar_selected_profile.jkr"


function G.FUNCS.deliberately_load_profile_wrapper(delete_prof_data)
    print("bro?--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    print("Saving")
    print(G.focused_profile)
    compress_and_save(selected_profile_filename, {G.focused_profile})
    -- Game:load_profile(delete_prof_data)
    print("jk")
end

function automatically_load_profile() 
    local selected_profile = STR_UNPACK(get_compressed(selected_profile_filename))
    print(":)")
    print(selected_profile)
    print(selected_profile[1])
    if selected_profile then
        Game:load_profile(selected_profile[1])
    else
        print("hmm...")
    end
end

G.FUNCS.can_load_profile_wrapper = function(e)
    G.FUNCS.can_load_profile(e)
    if e.config.button == 'load_profile' then
        e.config.button = 'deliberately_load_profile_wrapper'
    end
  end

function init()
    print("heygggg--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    for i=1,profile_count do
        print("l")
        if not G.PROFILES[i] then
            G.PROFILES[i] = {}
            print("lol")
        end
    end

    automatically_load_profile()
end
init()



function Game:start_up()
   print("hey--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    -- for i=1,profile_count do
    --     print("l")
    --     if not G.PROFILES[i] then
    --         G.PROFILES[i] = {}
    --         print("lol")
    --     end
    -- end
end
function Game:init()
   print("init--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    -- for i=1,profile_count do
    --     print("l")
    --     if not G.PROFILES[i] then
    --         G.PROFILES[i] = {}
    --         print("lol")
    --     end
    -- end
end

-- putting the saturn button on the main menu

-- local create_UIBox_main_menu_buttons_ref = create_UIBox_main_menu_buttons
-- function create_UIBox_main_menu_buttons()
    
--    local text_scale = 0.45
--     local extra_profiles_button = UIBox_button{button = 'extra_profiles_button', colour = G.C.ORANGE, minw = 2.65, minh = 1.35, label = {"Hey :)"}, scale = text_scale * 1.2, col = true}
-- --   local extra_profiles_button = UIBox_button({
-- --     id = "extra_profiles_button",
-- --     minh = 1.35,
-- --     minw = 1.85,
-- --     col = true,
-- --     button = "extra_profiles_button",
-- --     colour = G.C.FOIL,
-- --     label = { "Profiles+" },
-- --     scale = text_scale * 1.2,
-- --   })
--    local menu = create_UIBox_main_menu_buttons_ref()
--    local spacer = G.F_QUIT_BUTTON and { n = G.UIT.C, config = { align = "cm", minw = 0.2 }, nodes = {} } or nil
--    table.insert(menu.nodes[1].nodes[1].nodes[2].nodes, 2, spacer)
--    table.insert(menu.nodes[1].nodes[1].nodes[2].nodes, 3, extra_profiles_button)
--    menu.nodes[1].nodes[1].config =
--      { align = "cm", padding = 0.15, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true }
--   return menu
-- end

function create_UIBox_profile_button()

    local letters = {}
    if G.F_DISP_USERNAME then
      for _, c in utf8.chars(G.F_DISP_USERNAME) do
        local _char = c
        local leng = G.LANGUAGES['all1'].font.FONT:hasGlyphs(c)
        letters[#letters+1] = {n=G.UIT.T, config={lang = G.LANGUAGES[leng and 'all1' or 'all2'],text = _char, scale = 0.3, colour = mix_colours(G.C.GREEN, G.C.WHITE, 0.7), shadow = true}}
      end
    end
  
    if not G.PROFILES[G.SETTINGS.profile].name then 
      G.PROFILES[G.SETTINGS.profile].name = "P"..G.SETTINGS.profile
    end
  
   return {n=G.UIT.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.T, config={text = localize('k_profile') .. " (Cool version)", scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", padding = 0.15, minw = 2, minh = 10.8, maxw = 2, r = 0.1, hover = true, colour = mix_colours(G.C.WHITE, G.C.GREY, 0.2), button = 'profile_select', shadow = true}, nodes={
            {n=G.UIT.T, config={ref_table = G.PROFILES[G.SETTINGS.profile], ref_value = 'name', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
          }},
        }}
      }},
      G.F_DISP_USERNAME and {n=G.UIT.R, config={align = "cm"}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.T, config={text = localize('k_playing_as'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
        }},
        {n=G.UIT.R, config={align = "cm", minh = 0.12}, nodes={}},
        {n=G.UIT.R, config={align = "cm", maxw = 2}, nodes=letters}
      }} or nil,
    }}
  end

function G.FUNCS.extra_profiles_button()
    print("lolol")
    G.UIDEF.profile_select()
end

function G.UIDEF.profile_select()
    G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
    
    local tabs = {}
    for i=1,profile_count do
        tabs[i] = {
            label = i,
            chosen = G.focused_profile == i,
            tab_definition_function = G.UIDEF.profile_option,
            tab_definition_function_args = i
        }
    end

    local t =   create_UIBox_generic_options({padding = 0,contents ={
        {n=G.UIT.R, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
          create_tabs(
          {tabs = tabs,
          snap_to_nav = true}),
        }},
    }})
    return t
  end
  
  function G.UIDEF.profile_option(_profile)
    -- New
    print("this DOES run, right? ---------------------------------------------------------------------------------------------")
    if not G.PROFILES[_profile] then
        G.PROFILES[_profile] = {}
    end

    -- Original

    set_discover_tallies()
    G.focused_profile = _profile
    local profile_data = get_compressed(G.focused_profile..'/'..'profile.jkr')
      if profile_data ~= nil then
        profile_data = STR_UNPACK(profile_data)
        profile_data.name = profile_data.name or ("P".._profile)
      end
    G.PROFILES[_profile].name = profile_data and profile_data.name or ''
  
    local lwidth, rwidth, scale = 1, 1, 1
    G.CHECK_PROFILE_DATA = nil
    local t = {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes={
      {n=G.UIT.R, config={align = 'cm',padding = 0.1, minh = 0.8}, nodes={
          ((_profile == G.SETTINGS.profile) or not profile_data) and {n=G.UIT.R, config={align = "cm"}, nodes={
          create_text_input({
            w = 4, max_length = 16, prompt_text = localize('k_enter_name'),
            ref_table = G.PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
            callback = function() 
              G:save_settings()
              G.FILE_HANDLER.force = true
            end
          }),
        }} or {n=G.UIT.R, config={align = 'cm',padding = 0.1, minw = 4, r = 0.1, colour = G.C.BLACK, minh = 0.6}, nodes={
          {n=G.UIT.T, config={text = G.PROFILES[_profile].name, scale = 0.45, colour = G.C.WHITE}},
        }},
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
        {n=G.UIT.C, config={align = "cm", minw = 6}, nodes={
          (G.PROFILES[_profile].progress and G.PROFILES[_profile].progress.discovered) and create_progress_box(G.PROFILES[_profile].progress, 0.5) or
          {n=G.UIT.C, config={align = "cm", minh = 4, minw = 5.2, colour = G.C.BLACK, r = 0.1}, nodes={
            {n=G.UIT.T, config={text = localize('k_empty_caps'), scale = 0.5, colour = G.C.UI.TRANSPARENT_LIGHT}}
          }},
        }},
        {n=G.UIT.C, config={align = "cm", minh = 4}, nodes={
          {n=G.UIT.R, config={align = "cm", minh = 1}, nodes={
            profile_data and {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.C, config={align = "cm", minw = lwidth}, nodes={{n=G.UIT.T, config={text = localize('k_wins'),colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
              {n=G.UIT.C, config={align = "cm"}, nodes={{n=G.UIT.T, config={text = ': ',colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
              {n=G.UIT.C, config={align = "cl", minw = rwidth}, nodes={{n=G.UIT.T, config={text = tostring(profile_data.career_stats.c_wins),colour = G.C.RED, shadow = true, scale = 1*scale}}}}
            }} or nil,
          }},
          {n=G.UIT.R, config={align = "cm", padding = 0.2}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0},
                nodes={{
                    n=G.UIT.R, config={
                        align = "cm", 
                        minw = 4, 
                        maxw = 4, 
                        minh = 0.8, 
                        padding = 0.2, 
                        r = 0.1, 
                        hover = true, 
                        colour = G.C.BLUE,
                        func = 'can_load_profile_wrapper', 
                        button = "this doesn't matter lololololol boy it'll be really embarassing if this text shows up in an error message", 
                        shadow = true, 
                        focus_args = {nav = 'wide'}
                    }, 
                    nodes={{
                        n=G.UIT.T, 
                        config={
                            text = _profile == G.SETTINGS.profile and localize('b_current_profile') or profile_data and localize('b_load_profile').."burp" or localize('b_create_profile'), 
                            ref_value = 'load_button_text', 
                            scale = 0.5, 
                            colour = G.C.UI.TEXT_LIGHT
                        }
                    }}
                }}
            },
            {n=G.UIT.R, config={align = "cm", padding = 0, minh = 0.7}, nodes={
              {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.RED,func = 'can_delete_profile', button = "delete_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
                {n=G.UIT.T, config={text = _profile == G.SETTINGS.profile and localize('b_reset_profile') or localize('b_delete_profile'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
              }}
            }},
            (_profile == G.SETTINGS.profile and not G.PROFILES[G.SETTINGS.profile].all_unlocked) and {n=G.UIT.R, config={align = "cm", padding = 0, minh = 0.7}, nodes={
              {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.ORANGE,func = 'can_unlock_all', button = "unlock_all", shadow = true, focus_args = {nav = 'wide'}}, nodes={
                {n=G.UIT.T, config={text = localize('b_unlock_all'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
              }}
            }} or {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.7}, nodes={
              G.PROFILES[_profile].all_unlocked and ((not G.F_NO_ACHIEVEMENTS) and {n=G.UIT.T, config={text = localize(G.F_TROPHIES and 'k_trophies_disabled' or 'k_achievements_disabled'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}} or 
                nil) or nil
            }},
          }},
      }},
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
        {n=G.UIT.T, config={id = 'warning_text', text = localize('ph_click_confirm'), scale = 0.4, colour = G.C.CLEAR}}
      }}
    }} 
    return t
  end