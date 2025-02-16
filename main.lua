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

  initial_page = math.floor(G.SETTINGS.profile / profiles_per_page) + 1
  G.focused_profile = G.SETTINGS.profile

  -- Not sure what this does
  -- Maybe it's what opens the box in the first place?
  G.E_MANAGER:add_event(
    Event({
      func = (function()
        G.FUNCS.fwt_change_profile_list_page{
          cycle_config = {
            current_option = initial_page
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
                  current_option = initial_page,
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
              object = Moveable(),
              colour=G.C.DARK_EDITION
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
-- Said container is in its own container in create_UIBox_generic_options
function G.UIDEF.fwt_profile_list_page(_page)
  -- G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
  roll_focused_profile_with_page(_page)
  
  -- Snapped is set to false on the first iteration, and true on every other.
  -- It can be true at first if the below check passes. idk what for
  -- turing it on for everything then off for everything didn't help
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

            -- vert is what makes it go on the left!!!! took me a while to get that
            -- ssee engline/ui.lua line 840 in the balatro source code
            chosen=G.focused_profile==k and 'vert' or false,
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
    -- This is the list of dudes generated in fwt_profile_list_page
    local ch_list = G.OVERLAY_MENU:get_UIE_by_ID('fwt_profile_list')
    if ch_list then 
      -- Delete everything that's already there?
      if ch_list.config.object then 
        ch_list.config.object:remove() 
      end
      -- Oka, it like, replaces it with the same? Might even be the same actual code
      ch_list.config.object = UIBox{
        definition =  G.UIDEF.fwt_profile_list_page(args.cycle_config.current_option-1),
        config = {offset = {x=0,y=0}, align = 'cm', parent = ch_list, colour=G.C.BLACK}
      }
      -- Update the description, too
      G.FUNCS.fwt_change_profile_description{config = {id = G.focused_profile, colour=G.C.BLACK}}
    end
  end
end

-- Seems e.config.id tells it what to change to?
G.FUNCS.fwt_change_profile_description = function(e)
  if G.OVERLAY_MENU then
    
    -- The profile you're playing with is selected when the box is loaded
    -- The challenge menu didn't load anything at first
    -- So it needs help :)
    -- This removes the arrow when you click off of it 
    local initial_button = G.OVERLAY_MENU:get_UIE_by_ID(G.SETTINGS.profile)
    --print(e.config.chosen)
    if initial_button and e.last_moved ~= nil then  -- e has like a million more values on the first manual selection. it's jank but I'm just checking for one of them
      initial_button.config.chosen = nil
    end
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

-- The function called by the button that opens the box :)
function G.FUNCS.profile_select(e)
  G.SETTINGS.paused = true
  G.focused_profile = G.SETTINGS.PROFILE

  G.FUNCS.overlay_menu{
    definition = G.UIDEF.fwt_profile_list(),
  }
end
  
function G.UIDEF.profile_option(_profile)
    -- New
    if not G.PROFILES[_profile] then
        G.PROFILES[_profile] = {}
    end

    -- So the text prompt for entering a name was super misaligned, not even in the box
    -- no idea why
    -- but if you put a second input after it, *that* one works
    -- and if you put a second input *before* it, the *original* works
    -- I am not paid
    funny_fix = create_text_input({
      w = 0,
      padding=0,
      h=0,
      prompt_text = '',
      colour=copy_table(G.C.CLEAR),
      hooked_colour=copy_table(G.C.CLEAR),
      ref_table = {uh=''}, ref_value = 'uh',
    })
    function shrink(t)
      if t.config then
        t.config.padding=0
        -- t.config.w=0 These two make it not count...
        -- t.config.h=0
        t.config.scale=0
        t.config.text_scale=0
        -- t.config.colour=copy_table(G.C.CLEAR)
        -- t.config.hooked_colour=copy_table(G.C.CLEAR)
      end
      if t.nodes then
        for _, value in pairs(t.nodes) do
          shrink(value)
        end
      end
    end
    --shrink(funny_fix)

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
    local t = {
      n=G.UIT.ROOT, -- was root
      config={
        align = 'cm', 
        colour = G.C.BLUE, -- was clear
      }, 
      nodes=
      {
        funny_fix, -- new
        {
          n=G.UIT.R, 
          config={
            align = 'cm',
            padding = 0.1, 
            minh = 0.8,
            colour=G.C.BLACK, -- was mpthing
            tooltip={title = "Sorry", text = {"I have no clue how to fix this", "(you'll see)"}},
          }, 
          nodes={
            (
              -- Prompt to enter or change name 
              (_profile == G.SETTINGS.profile) or not profile_data) and {
                n=G.UIT.R, 
                config={
                  align = "cm",
                  colour=G.C.GREEN, -- was mpthing
                  tooltip={title = "Sorry", text = {"I have no clue how to fix this", "(you'll see)"}},
                }, 
                nodes={
                  create_text_input({
                    w = 4,
                    config={
                      align='cm',
                      colour=G.C.RED, -- was mpthing
                      tooltip={title = "Sorry", text = {"I have no clue how to fix this", "(you'll see)"}},
                    },
                    colour=G.C.MONEY, -- was mpthing
                    align='cm',
                    max_length = 16, 
                    prompt_text = localize('k_enter_name'),
                    ref_table = G.PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
                    callback = function() 
                      G:save_settings()
                      G.FILE_HANDLER.force = true
                    end
                  }),
                }

              -- Name is fixed
              } or {
                n=G.UIT.R, 
                config={
                  align = 'cm',
                  padding = 0.1, 
                  minw = 4, 
                  r = 0.1, 
                  colour = G.C.BLACK, 
                  minh = 0.6
                }, 
                nodes={
                  {
                    n=G.UIT.T, 
                    config={
                      text = G.PROFILES[_profile].name, 
                      scale = 0.45, 
                      colour = G.C.WHITE
                    }
                  },
                }
              },
            }
          },
          {n=G.UIT.R, 
          config={
            align = "cm", 
            padding = 0.1
          }, 
          nodes={
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
                        button = "g",--"this doesn't matter lololololol boy it'll be really embarassing if this text shows up in an error message", 
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

    -- local ch_list = G.OVERLAY_MENU:get_UIE_by_ID('waaaaaaaaaaaaa')
    -- if ch_list then 
    --   -- Delete everything that's already there?
    --   if ch_list.config.object then 
    --     ch_list.config.object:remove() 
    --   end
    -- end
    return t
  end