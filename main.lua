local profile_count = 8
local profiles_per_page = 4
local selected_profile_filename = "fwt_selected_profile.jkr"

-- TODO: changing the name should update it in the sidebar

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

-- Seems to be the whole ass popup?
function G.UIDEF.fwt_profile_list()
  local profile_pages = {}
  for i = 1, math.ceil(profile_count/profiles_per_page) do
    table.insert(profile_pages, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(profile_count/profiles_per_page)))
  end

  -- Not sure what this does
  -- Maybe it's what opens the box in the first place?
  G.E_MANAGER:add_event(
    Event({
      func = (function()
        G.FUNCS.fwt_change_profile_list_page{
          cycle_config = {
            current_option = 1   -- TODO or maybe this is how you change the initial page at first?
          }
        }
        return true
      end)
    })
  )

  -- Seems to be the whole ass popup?
  local t = create_UIBox_generic_options({
    back_id = 'fwt_profile_list',
    contents = {
      {
        n=G.UIT.C, 
        config={
          align = "cm", 
          padding = 0.0, 
          colour=G.C.MONEY
        }, 
        nodes={
          {
            n=G.UIT.R, 
            config={
              align = "cm", 
              padding = 0.1, 
              minh = 7, 
              minw = 4.2
            }, 
            nodes={
              {
                n=G.UIT.O,
                config={
                  id = 'fwt_profile_list',
                  object = Moveable()
                }
              },
            }
          },
          {
            -- The container for the <- Page 1/2 -> guy
            n=G.UIT.R, 
            config={
              align = "cm", 
              padding = 0.1, 
              colour=G.C.RED
            }, 
            nodes={
              -- The <- Page 1/2 -> guy
              create_option_cycle({
                  id = 'fwt_profile_page',
                  scale = 0.9, 
                  h = 0.3, 
                  w = 3.5, 
                  options = profile_pages, 
                  cycle_shoulders = true,
                  opt_callback = 'fwt_change_profile_list_page',
                  current_option = 1,  -- TODO hey I bet this is how you change the initial page at first
                  colour = G.C.RED, 
                  no_pips = true, 
                  focus_args = {
                    snap_to = true
                  }
              })
            }
          },
        }
      },
      {
        n=G.UIT.C, 
        config={
          align = "cm", 
          minh = 9, 
          minw = 11.5
        }, 
        nodes={
          {
            n=G.UIT.O, 
            config={
              id = 'fwt_profile_area', 
              object = Moveable()
            }
          },
        }
      },
    }
  })
  return t
end

function roll_focused_profile_with_page(page) 
  -- Boy! I sure hope this makes sense
  if not page then
    page = 1
  end

  if not G.focused_profile or G.focused_profile == 'nil' or G.focused_profile == nil then
    G.focused_profile = 1 -- TODO this should instead pick the current profile!! but it might not be on this page!! sooooooo
    if G.focused_profile == 'nil' or G.focused_profile == nil then
      print("Hey if you're reading this please ask Dust to fix it so that she can say \"yeah I'll do it later\" and then never do it")
    end
  else
    -- Adding profiles_per_page because it seems to be able to be negative?
    G.focused_profile = math.fmod(G.focused_profile -1, profiles_per_page) + (page) * profiles_per_page + 1
  end
end

-- The actual list part, like, the numbered rows, and their container
-- Said container is in its own container in 
function G.UIDEF.fwt_profile_list_page(_page)
  -- G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
  roll_focused_profile_with_page(_page)
  
  -- Snapped is set to false on the first iteration, and true on every other.
  -- It can be true at first if the below check passes. idk what for
  local snapped = false 
  local fwt_profile_list = {}
  for k=1,profile_count do
    -- If this profile is actuallyy on the page...
    if k > profiles_per_page*(_page or 0) and k <= profiles_per_page*((_page or 0) + 1) then

      -- Make sure all profiles are initialized (should probably be moved elsewhere?) TODO
      if love.filesystem.getInfo(k..'/'..'profile.jkr') then G:load_profile(k) end
      if not G.PROFILES[k] then
        G.PROFILES[k] = {}
      end
      if not G.PROFILES[k].name then
        G.PROFILES[k].name = 'P'..k
      end
    
      profile_being_rendered = G.PROFILES[k]
      if G.CONTROLLER.focused.target and G.CONTROLLER.focused.target.config.id == 'fwt_profile_page' then
        snapped = true
      end

      fwt_profile_list[#fwt_profile_list+1] = 
      {
        -- Row in that list, with the number and button
        n=G.UIT.R, 
        config={align = "cm"}, 
        nodes={
          {
            n=G.UIT.C, 
            config={
              align = 'cl', 
              minw = 0.8
            }, 
            nodes = {
              -- The numbers to the left of the options
              {
                n=G.UIT.T, 
                config={
                  text = k..'',
                  scale = 0.4, 
                  colour = G.C.WHITE
                }
              },
            }
          },
          -- The button that displays the name and you click on to get more information
          UIBox_button({
            id = k,
            col = true, 
            label = {
              profile_being_rendered.name and G.focused_profile..' '..G.SETTINGS.profile..' '..k..' '..profile_being_rendered.name
              or profile_being_rendered.name
            },
            button = 'fwt_change_profile_description', -- TODO eyes
            colour = G.C.RED,
            minw = 4,
            scale = 0.4,
            minh = 0.6,
            focus_args = {
              snap_to = not snapped
            }
          }),

          -- Held the little radio buttons that show if a challenge is done.
          -- But they'll be nice if I want extra information later, maybe?
        -- {n=G.UIT.C, config={align = 'cm', padding = 0.05, minw = 0.6}, nodes = {
        --   -- {n=G.UIT.C, config={minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1, colour = G.C.BLUE}, nodes = {
        --   --   -- challenge_completed and {n=G.UIT.O, config={object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS["icons"], {x=1, y=0})}} or nil
        --   -- }},
        -- }},
      }}      
      snapped = true
    end
  end

  return {n=G.UIT.ROOT, config={align = "cm", padding = 0.1, colour = G.C.BLUE}, nodes=fwt_profile_list}
end

-- Seems to be called when the box is opened and when the page is changed?
G.FUNCS.fwt_change_profile_list_page = function(args)
  -- Seems the rolling args are:
  -- from_val = from_val,
  --     to_val = to_val,
  --     from_key = from_key,
  --     to_key = to_key,
  --     cycle_config = e.config.ref_table
  roll_focused_profile_with_page(args.to_key)
  if not args or not args.cycle_config then return end
  if G.OVERLAY_MENU then
    local ch_list = G.OVERLAY_MENU:get_UIE_by_ID('fwt_profile_list')
    if ch_list then 
      if ch_list.config.object then 
        ch_list.config.object:remove() 
      end
      ch_list.config.object = UIBox{
        definition =  G.UIDEF.fwt_profile_list_page(args.cycle_config.current_option-1),
        config = {offset = {x=0,y=0}, align = 'cm', parent = ch_list, colour=G.C.BLACK}
      }
      G.FUNCS.fwt_change_profile_description{config = {id = G.focused_profile, colour=G.C.BLACK}}
    end
  end
end

-- Seems e.config.id tells it what to change to?
G.FUNCS.fwt_change_profile_description = function(e)
  if G.OVERLAY_MENU then
    
    -- fwt_profile_list seems to be a 
    local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('fwt_profile_area')
    if desc_area and desc_area.config.oid ~= e.config.id then
      if desc_area.config.old_chosen then desc_area.config.old_chosen.config.chosen = nil end
      
      e.config.chosen = 'vert'
      if desc_area.config.object then 
        desc_area.config.object:remove() 
      end
      desc_area.config.object = UIBox{
        definition =  G.UIDEF.profile_option(e.config.id),
        config = {
          offset = {x=0,y=0}, 
          align = 'cm', 
          parent = desc_area}
      }
      desc_area.config.oid = e.config.id 
      desc_area.config.old_chosen = e
    end
  end
end


function G.FUNCS.profile_select(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = G.UIDEF.fwt_profile_list((false)),
  }
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