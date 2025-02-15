local profile_count = 8
local profiles_per_page = 4
local selected_profile_filename = "fwt_selected_profile.jkr"


function G.FUNCS.deliberately_load_profile_wrapper(delete_prof_data)
    compress_and_save(selected_profile_filename, {G.focused_profile})
    G.FUNCS.load_profile(delete_prof_data)  -- I'm playing with fire here. what does delete_prof_data DO
end

function automatically_load_profile() 
    local file_contents = get_compressed(selected_profile_filename)
    if not file_contents then
      return
    end
    local selected_profile = STR_UNPACK(file_contents)

    if selected_profile then
        Game:load_profile(selected_profile[1])
    end
end

G.FUNCS.can_load_profile_wrapper = function(e)
    G.FUNCS.can_load_profile(e)
    if e.config.button == 'load_profile' then
        e.config.button = 'deliberately_load_profile_wrapper'
    end
  end

function init()
    for i=1,profile_count do
        if not G.PROFILES[i] then
            G.PROFILES[i] = {}
        end
    end

    automatically_load_profile()
end
init()

-- function G.FUNCS.extra_profiles_button()
--     G.UIDEF.profile_select()
-- end

-- So I THINK this is gone now? It's the profdile select box with the three (eight) guys on top
-- function G.UIDEF.profile_select()
--   print("yeah can I get uuuhhhhhhh")
--   G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1

--   tabs = {}
--   for i=1,profile_count do
--     if love.filesystem.getInfo(i..'/'..'profile.jkr') then G:load_profile(i) end
--     tabs[i] = {
--         label = G.PROFILES[i].name and G.PROFILES[i].name or i,
--         chosen = G.focused_profile == i,
--         tab_definition_function = G.UIDEF.profile_option,
--         tab_definition_function_args = i,
--     }
--   end

--   local t =   create_UIBox_generic_options({padding = 0,contents ={
--       {n=G.UIT.R, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
--         create_tabs(
--         {tabs = tabs,
--         snap_to_nav = true}),
--       }},
--   }})
--   return t
-- end


function G.UIDEF.fwt_profile_list(from_game_over)
  print("-------------------------------------------------------3")
  local profile_pages = {}
  for i = 1, math.ceil(profile_count/profiles_per_page) do
    table.insert(profile_pages, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(profile_count/profiles_per_page)))
  end
  G.E_MANAGER:add_event(Event({func = (function()
    G.FUNCS.fwt_change_profile_list_page{cycle_config = {current_option = 1}}
  return true end)}))

  -- Counts completed challenges, don't care 
  -- local _ch_comp, _ch_tot = 0, profile_count
  -- for k, v in ipairs(G.CHALLENGES) do
  --   if v.id and G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id or ''] then
  --     _ch_comp = _ch_comp + 1
  --   end
  -- end

  local t = create_UIBox_generic_options({ back_id = from_game_over and 'from_game_over' or nil, back_func = 'setup_run', back_id = 'fwt_profile_list', contents = {
    {n=G.UIT.C, config={align = "cm", padding = 0.0, colour=G.C.GREEN}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.1, minh = 7, minw = 4.2}, nodes={
        {n=G.UIT.O, config={id = 'fwt_profile_list', object = Moveable()}},
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0.1, colour=G.C.RED}, nodes={
        create_option_cycle({id = 'challenge_page',scale = 0.9, h = 0.3, w = 3.5, options = profile_pages, cycle_shoulders = true, opt_callback = 'fwt_change_profile_list_page',
        current_option = 1,
        colour = G.C.RED, no_pips = true, focus_args = {snap_to = true}})
      }},
      -- This just lists how many challenges are completed (irrelevant)
      -- {n=G.UIT.R, config={align = "cm", padding = 0.1, colour=G.C.MONEY}, nodes={
      --   {n=G.UIT.T, config={text = localize{type = 'variable', key = 'challenges_completed', vars = {_ch_comp, _ch_tot}}, scale = 0.4, colour = G.C.WHITE}},
      -- }},

    }},
    {n=G.UIT.C, config={align = "cm", minh = 9, minw = 11.5}, nodes={
      {n=G.UIT.O, config={id = 'challenge_area', object = Moveable()}},
    }},
  }})
  return t
end

function roll_focused_profile_with_page(page) 
  -- Boy! I sure hope this makes sense
  if not page then
    page = 1
  end

  print("Page is "..page)
  if G.focused_profile then
    print("focused_profile was "..G.focused_profile)
  end

  if not G.focused_profile or G.focused_profile == 'nil' or G.focused_profile == nil then
    G.focused_profile = 1 -- TODO this should instead pick the current profile!! but it might not be on this page!! sooooooo
    if G.focused_profile == 'nil' or G.focused_profile == nil then
      print("Hey if you're reading this please ask Dust to fix it so that she can say \"yeah I'll do it later\" and then never do it")
    end
  else
    print(G.focused_profile)
    -- Adding profiles_per_page because it seems to be able to be negative?
    G.focused_profile = math.fmod(G.focused_profile -1, profiles_per_page) + (page) * profiles_per_page + 1
    print("focused_profile is "..G.focused_profile)
  end
end

function G.UIDEF.fwt_profile_list_page(_page)
  -- G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
  roll_focused_profile_with_page(_page)
  
  print("-------------------------------------------------------1")
  local snapped = false
  local fwt_profile_list = {}
  for k=1,profile_count do
    if love.filesystem.getInfo(k..'/'..'profile.jkr') then G:load_profile(k) end
    if not G.PROFILES[k] then
      G.PROFILES[k] = {}
    end
    v = G.PROFILES[k]
    if k > profiles_per_page*(_page or 0) and k <= profiles_per_page*((_page or 0) + 1) then
      print("hhhhhhrtjdesjghjredsjgijershjfcsejhfvbhkjdxtvhhjdfhgjikldtf")  
      if G.CONTROLLER.focused.target and G.CONTROLLER.focused.target.config.id == 'challenge_page' then snapped = true end

        fwt_profile_list[#fwt_profile_list+1] = 
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = 'cl', minw = 0.8}, nodes = {
            {n=G.UIT.T, config={text = k..'', scale = 0.4, colour = G.C.WHITE}},
          }},
          UIBox_button({id = k, col = true, label = {v.name and G.focused_profile..' '..G.SETTINGS.profile..' '..k..' '..v.name or v.name}, button = 'fwt_change_profile_description', colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6, focus_args = {snap_to = not snapped}}),
          {n=G.UIT.C, config={align = 'cm', padding = 0.05, minw = 0.6}, nodes = {
            {n=G.UIT.C, config={minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1, colour = G.C.BLUE}, nodes = {
              -- challenge_completed and {n=G.UIT.O, config={object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS["icons"], {x=1, y=0})}} or nil
            }},
          }},
        }}      
        snapped = true
    end
  end

  return {n=G.UIT.ROOT, config={align = "cm", padding = 0.1, colour = G.C.GREEN}, nodes=fwt_profile_list}
end

G.FUNCS.fwt_change_profile_list_page = function(args)
  -- Seems the rolling args are:
  -- from_val = from_val,
  --     to_val = to_val,
  --     from_key = from_key,
  --     to_key = to_key,
  --     cycle_config = e.config.ref_table
  print(args)
  roll_focused_profile_with_page(args.to_key)
  print("-------------------------------------------------------2")
  if not args or not args.cycle_config then return end
  print("-------------------------------------------------------22")
  if G.OVERLAY_MENU then
    print("-------------------------------------------------------222")
    local ch_list = G.OVERLAY_MENU:get_UIE_by_ID('fwt_profile_list')
    if ch_list then 
      if ch_list.config.object then 
        ch_list.config.object:remove() 
      end
      print("-------------------------------------------------------2222")
      ch_list.config.object = UIBox{
        definition =  G.UIDEF.fwt_profile_list_page(args.cycle_config.current_option-1),
        config = {offset = {x=0,y=0}, align = 'cm', parent = ch_list, colour=G.C.BLACK}
      }
      print("-------------------------------------------------------22222")
      G.FUNCS.fwt_change_profile_description{config = {id = G.focused_profile, colour=G.C.BLACK}}
      print("-------------------------------------------------------12")
    end
  end
  print("-------------------------------------------------------13")
end

-- Seems e.config.id tells it what to change to?
G.FUNCS.fwt_change_profile_description = function(e)
  print("-------------------------------------------------------7")
  if G.OVERLAY_MENU then
    print("-------------------------------------------------------8")
    
    local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('challenge_area')
    if desc_area and desc_area.config.oid ~= e.config.id then
      print("-------------------------------------------------------9")
      
      -- Dunno what this is for and it keeps becoming nil when I don't want it to so I'm trying commenting it out
      -- Didn't work but idkklkkkkkktrhiht
      if desc_area.config.old_chosen then desc_area.config.old_chosen.config.chosen = nil end
      
      e.config.chosen = 'vert'
      print("-------------------------------------------------------10")
      if desc_area.config.object then 
        desc_area.config.object:remove() 
      end
      print("-------------------------------------------------------11")
      desc_area.config.object = UIBox{
        definition =  G.UIDEF.profile_option(e.config.id),
        config = {offset = {x=0,y=0}, align = 'cm', parent = desc_area}
      }
      print("-------------------------------------------------------11yyyyyyyyyyyy")
      desc_area.config.oid = e.config.id 
      desc_area.config.old_chosen = e
    end
  end
  print("-------------------------------------------------------12")
end


-- G.FUNCS.deck_view_challenge = function(e)
--   G.FUNCS.overlay_menu{
--     definition = create_UIBox_generic_options({back_func = 'deck_info', contents ={
--         G.UIDEF.challenge_description(get_challenge_int_from_id(e.config.id.id or ''), nil, true)
--       }
--     })
--   }
-- end

function G.FUNCS.profile_select(e)
  print("-------------------------------------------------------60")
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = G.UIDEF.fwt_profile_list((false)),
  }
  print("-------------------------------------------------------61")
end

function G.FUNCS.original_profile_behavior()

    G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
    
    local tabs = {}
    for i=1,profile_count do
        if love.filesystem.getInfo(i..'/'..'profile.jkr') then G:load_profile(i) end
        tabs[i] = {
            label = G.PROFILES[i].name and G.PROFILES[i].name or i,
            chosen = G.focused_profile == i,
            tab_definition_function = G.UIDEF.profile_option,
            tab_definition_function_args = i,
        }
    end
    G:load_profile(G.focused_profile)

    print("uwuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu")
    local t = create_UIBox_generic_options({padding = 0,contents ={
        {n=G.UIT.R, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
          create_tabs(
          {
            tabs = tabs,
            scale=0.5,
            text_scale=0.25,
            snap_to_nav = true
          }),
        }},
    }})
    return t
  end
  
  function G.UIDEF.profile_option(_profile)
    -- New
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
                            text = _profile == G.SETTINGS.profile and localize('b_current_profile').._profile or profile_data and localize('b_load_profile').._profile or localize('b_create_profile').._profile, 
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