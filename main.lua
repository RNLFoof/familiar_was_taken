local profile_count = 8
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



function G.UIDEF.fwt_profile_list(from_game_over)
  print("-------------------------------------------------------3")
  G.CHALLENGE_PAGE_SIZE = 10
  local challenge_pages = {}
  for i = 1, math.ceil(#G.CHALLENGES/G.CHALLENGE_PAGE_SIZE) do
    table.insert(challenge_pages, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.CHALLENGES/G.CHALLENGE_PAGE_SIZE)))
  end
  G.E_MANAGER:add_event(Event({func = (function()
    G.FUNCS.fwt_change_profile_list_page{cycle_config = {current_option = 1}}
  return true end)}))

  local _ch_comp, _ch_tot = 0,#G.CHALLENGES
  for k, v in ipairs(G.CHALLENGES) do
    if v.id and G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id or ''] then
      _ch_comp = _ch_comp + 1
    end
  end

  local t = create_UIBox_generic_options({ back_id = from_game_over and 'from_game_over' or nil, back_func = 'setup_run', back_id = 'fwt_profile_list', contents = {
    {n=G.UIT.C, config={align = "cm", padding = 0.0, colour=G.C.GREEN}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.1, minh = 7, minw = 4.2}, nodes={
        {n=G.UIT.O, config={id = 'fwt_profile_list', object = Moveable()}},
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0.1, colour=G.C.RED}, nodes={
        create_option_cycle({id = 'challenge_page',scale = 0.9, h = 0.3, w = 3.5, options = challenge_pages, cycle_shoulders = true, opt_callback = 'fwt_change_profile_list_page', current_option = 1, colour = G.C.RED, no_pips = true, focus_args = {snap_to = true}})
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0.1, colour=G.C.MONEY}, nodes={
        {n=G.UIT.T, config={text = localize{type = 'variable', key = 'challenges_completed', vars = {_ch_comp, _ch_tot}}, scale = 0.4, colour = G.C.WHITE}},
      }},

    }},
    {n=G.UIT.C, config={align = "cm", minh = 9, minw = 11.5}, nodes={
      {n=G.UIT.O, config={id = 'challenge_area', object = Moveable()}},
    }},
  }})
  return t
end

function G.UIDEF.fwt_profile_list_page(_page)
  print("-------------------------------------------------------1")
  local snapped = false
  local fwt_profile_list = {}
  for k, v in ipairs({
    {
        name = 'The Omelette',
        id = 'c_omelette_1',
        rules = {
            custom = {
                {id = 'no_reward'},
                {id = 'no_extra_hand_money'},
                {id = 'no_interest'}
            },
            modifiers = {
            }
        },
        jokers = {
            {id = 'j_egg'},
            {id = 'j_egg'},
            {id = 'j_egg'},
            {id = 'j_egg'},
            {id = 'j_egg'},
        },
        consumeables = {
        },
        vouchers = {
        },
        deck = {
            type = 'Challenge Deck'
        },
        restrictions = {
            banned_cards = {
                {id = 'v_seed_money'},
                {id = 'v_money_tree'},
                {id = 'j_to_the_moon'},
                {id = 'j_rocket'},
                {id = 'j_golden'},
                {id = 'j_satellite'},
            },
            banned_tags = {
            },
            banned_other = {
            }
        }
    }}) do
    if k > G.CHALLENGE_PAGE_SIZE*(_page or 0) and k <= G.CHALLENGE_PAGE_SIZE*((_page or 0) + 1) then
      if G.CONTROLLER.focused.target and G.CONTROLLER.focused.target.config.id == 'challenge_page' then snapped = true end
      local challenge_completed =  G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id or '']
      local challenge_unlocked = G.PROFILES[G.SETTINGS.profile].challenges_unlocked and (G.PROFILES[G.SETTINGS.profile].challenges_unlocked >= k)

      fwt_profile_list[#fwt_profile_list+1] = 
      {n=G.UIT.R, config={align = "cm"}, nodes={
        {n=G.UIT.C, config={align = 'cl', minw = 0.8}, nodes = {
          {n=G.UIT.T, config={text = k..'', scale = 0.4, colour = G.C.WHITE}},
        }},
        UIBox_button({id = k, col = true, label = {challenge_unlocked and localize(v.id, 'challenge_names') or localize('k_locked'),}, button = challenge_unlocked and 'fwt_change_profile_description' or 'nil', colour = challenge_unlocked and G.C.RED or G.C.GREY, minw = 4, scale = 0.4, minh = 0.6, focus_args = {snap_to = not snapped}}),
        {n=G.UIT.C, config={align = 'cm', padding = 0.05, minw = 0.6}, nodes = {
          {n=G.UIT.C, config={minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1, colour = challenge_completed and G.C.BLUE or G.C.BLACK}, nodes = {
            challenge_completed and {n=G.UIT.O, config={object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS["icons"], {x=1, y=0})}} or nil
          }},
        }},
      }}      
      snapped = true
    end
  end

  return {n=G.UIT.ROOT, config={align = "cm", padding = 0.1, colour = G.C.GREEN}, nodes=fwt_profile_list}
end

G.FUNCS.fwt_change_profile_list_page = function(args)
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
      G.FUNCS.fwt_change_profile_description{config = {id = 'nil', colour=G.C.BLACK}}
    end
  end
end

G.FUNCS.fwt_change_profile_description = function(e)
  print("-------------------------------------------------------7")
  if G.OVERLAY_MENU then
    local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('challenge_area')
    if desc_area and desc_area.config.oid ~= e.config.id then
      if desc_area.config.old_chosen then desc_area.config.old_chosen.config.chosen = nil end
      e.config.chosen = 'vert'
      if desc_area.config.object then 
        desc_area.config.object:remove() 
      end
      desc_area.config.object = UIBox{
        definition =  G.UIDEF.challenge_description(e.config.id),
        config = {offset = {x=0,y=0}, align = 'cm', parent = desc_area}
      }
      desc_area.config.oid = e.config.id 
      desc_area.config.old_chosen = e
    end
  end
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
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = G.UIDEF.fwt_profile_list((false)),
  }
end


  --   G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
    
  --   local tabs = {}
  --   for i=1,profile_count do
  --       if love.filesystem.getInfo(i..'/'..'profile.jkr') then G:load_profile(i) end
  --       tabs[i] = {
  --           label = G.PROFILES[i].name and G.PROFILES[i].name or i,
  --           chosen = G.focused_profile == i,
  --           tab_definition_function = G.UIDEF.profile_option,
  --           tab_definition_function_args = i,
  --       }
  --   end
  --   G:load_profile(G.focused_profile)

  --   local t = create_UIBox_generic_options({padding = 0,contents ={
  --       {n=G.UIT.R, config={align = "cm", padding = 0, draw_layer = 1, minw = 4}, nodes={
  --         create_tabs(
  --         {
  --           tabs = tabs,
  --           scale=0.5,
  --           text_scale=0.25,
  --           snap_to_nav = true
  --         }),
  --       }},
  --   }})
  --   return t
  -- end
  
  -- function G.UIDEF.profile_option(_profile)
  --   -- New
  --   if not G.PROFILES[_profile] then
  --       G.PROFILES[_profile] = {}
  --   end

  --   -- Original

  --   set_discover_tallies()
  --   G.focused_profile = _profile
  --   local profile_data = get_compressed(G.focused_profile..'/'..'profile.jkr')
  --     if profile_data ~= nil then
  --       profile_data = STR_UNPACK(profile_data)
  --       profile_data.name = profile_data.name or ("P".._profile)
  --     end
  --   G.PROFILES[_profile].name = profile_data and profile_data.name or ''
  
  --   local lwidth, rwidth, scale = 1, 1, 1
  --   G.CHECK_PROFILE_DATA = nil
  --   local t = {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes={
  --     {n=G.UIT.R, config={align = 'cm',padding = 0.1, minh = 0.8}, nodes={
  --         ((_profile == G.SETTINGS.profile) or not profile_data) and {n=G.UIT.R, config={align = "cm"}, nodes={
  --         create_text_input({
  --           w = 4, max_length = 16, prompt_text = localize('k_enter_name'),
  --           ref_table = G.PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
  --           callback = function() 
  --             G:save_settings()
  --             G.FILE_HANDLER.force = true
  --           end
  --         }),
  --       }} or {n=G.UIT.R, config={align = 'cm',padding = 0.1, minw = 4, r = 0.1, colour = G.C.BLACK, minh = 0.6}, nodes={
  --         {n=G.UIT.T, config={text = G.PROFILES[_profile].name, scale = 0.45, colour = G.C.WHITE}},
  --       }},
  --     }},
  --     {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
  --       {n=G.UIT.C, config={align = "cm", minw = 6}, nodes={
  --         (G.PROFILES[_profile].progress and G.PROFILES[_profile].progress.discovered) and create_progress_box(G.PROFILES[_profile].progress, 0.5) or
  --         {n=G.UIT.C, config={align = "cm", minh = 4, minw = 5.2, colour = G.C.BLACK, r = 0.1}, nodes={
  --           {n=G.UIT.T, config={text = localize('k_empty_caps'), scale = 0.5, colour = G.C.UI.TRANSPARENT_LIGHT}}
  --         }},
  --       }},
  --       {n=G.UIT.C, config={align = "cm", minh = 4}, nodes={
  --         {n=G.UIT.R, config={align = "cm", minh = 1}, nodes={
  --           profile_data and {n=G.UIT.R, config={align = "cm"}, nodes={
  --             {n=G.UIT.C, config={align = "cm", minw = lwidth}, nodes={{n=G.UIT.T, config={text = localize('k_wins'),colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
  --             {n=G.UIT.C, config={align = "cm"}, nodes={{n=G.UIT.T, config={text = ': ',colour = G.C.UI.TEXT_LIGHT, scale = scale*0.7}}}},
  --             {n=G.UIT.C, config={align = "cl", minw = rwidth}, nodes={{n=G.UIT.T, config={text = tostring(profile_data.career_stats.c_wins),colour = G.C.RED, shadow = true, scale = 1*scale}}}}
  --           }} or nil,
  --         }},
  --         {n=G.UIT.R, config={align = "cm", padding = 0.2}, nodes={
  --           {n=G.UIT.R, config={align = "cm", padding = 0},
  --               nodes={{
  --                   n=G.UIT.R, config={
  --                       align = "cm", 
  --                       minw = 4, 
  --                       maxw = 4, 
  --                       minh = 0.8, 
  --                       padding = 0.2, 
  --                       r = 0.1, 
  --                       hover = true, 
  --                       colour = G.C.BLUE,
  --                       func = 'can_load_profile_wrapper', 
  --                       button = "this doesn't matter lololololol boy it'll be really embarassing if this text shows up in an error message", 
  --                       shadow = true, 
  --                       focus_args = {nav = 'wide'}
  --                   }, 
  --                   nodes={{
  --                       n=G.UIT.T, 
  --                       config={
  --                           text = _profile == G.SETTINGS.profile and localize('b_current_profile') or profile_data and localize('b_load_profile') or localize('b_create_profile'), 
  --                           ref_value = 'load_button_text', 
  --                           scale = 0.5, 
  --                           colour = G.C.UI.TEXT_LIGHT
  --                       }
  --                   }}
  --               }}
  --           },
  --           {n=G.UIT.R, config={align = "cm", padding = 0, minh = 0.7}, nodes={
  --             {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.RED,func = 'can_delete_profile', button = "delete_profile", shadow = true, focus_args = {nav = 'wide'}}, nodes={
  --               {n=G.UIT.T, config={text = _profile == G.SETTINGS.profile and localize('b_reset_profile') or localize('b_delete_profile'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
  --             }}
  --           }},
  --           (_profile == G.SETTINGS.profile and not G.PROFILES[G.SETTINGS.profile].all_unlocked) and {n=G.UIT.R, config={align = "cm", padding = 0, minh = 0.7}, nodes={
  --             {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = G.C.ORANGE,func = 'can_unlock_all', button = "unlock_all", shadow = true, focus_args = {nav = 'wide'}}, nodes={
  --               {n=G.UIT.T, config={text = localize('b_unlock_all'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
  --             }}
  --           }} or {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 4, minh = 0.7}, nodes={
  --             G.PROFILES[_profile].all_unlocked and ((not G.F_NO_ACHIEVEMENTS) and {n=G.UIT.T, config={text = localize(G.F_TROPHIES and 'k_trophies_disabled' or 'k_achievements_disabled'), scale = 0.3, colour = G.C.UI.TEXT_LIGHT}} or 
  --               nil) or nil
  --           }},
  --         }},
  --     }},
  --     }},
  --     {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
  --       {n=G.UIT.T, config={id = 'warning_text', text = localize('ph_click_confirm'), scale = 0.4, colour = G.C.CLEAR}}
  --     }}
  --   }} 
  --   return t
  -- end