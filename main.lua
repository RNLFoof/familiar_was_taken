local profiles_per_page = 10
local profile_count = 3 * profiles_per_page
local selected_profile_filename = "fwt_selected_profile.jkr"

--------------- FUNCTIONS ---------------

function automatically_load_profile() 
  local file_contents = get_compressed(selected_profile_filename)
  if not file_contents then
    return
  end
  local selected_profile = STR_UNPACK(file_contents)

  if selected_profile then
    --Game:load_profile seems to be for game start
    --G.FUNCS.load_profile seems to be for the menus
    G.focused_profile = selected_profile[1]
    G.SETTINGS.PROFILE = selected_profile[1]
    print("it should be________________________________________________"..selected_profile[1])
    G.PROFILES[selected_profile[1]] = {}  -- if this isn't here it won't load. idk
    Game:load_profile(selected_profile[1])
  end
end

function init()
  automatically_load_profile()
end
init()

-- Lets you set the page. If left blank, figures it out from what profile is focused.
-- Rolls the selected profile if needed.
function ensure_or_set_current_page(optional_page)
  -- Profile part 
  if not G.focused_profile or G.focused_profile == 'nil' or G.focused_profile == nil then
    G.focused_profile = G.SETTINGS.profile
  end

  if optional_page ~= nil then
    G.fwt_current_page = optional_page
  end
  if G.fwt_current_page == nil then
    G.fwt_current_page = math.floor(G.SETTINGS.profile / profiles_per_page) + 1
  end

  -- Adding profiles_per_page because it seems to be able to be negative?
  G.focused_profile =  ((G.focused_profile-1) % profiles_per_page) + ((G.fwt_current_page-1) * profiles_per_page) + 1
  G.fwt_lower_page_bound = ((G.fwt_current_page-1) * profiles_per_page) + 1
  G.fwt_upper_page_bound = ((G.fwt_current_page) * profiles_per_page)

  local this_will_be_in_the_error________________________________ = {
    fwt_current_page = G.fwt_current_page,
    focused_profile = G.focused_profile,
    lower_bound = G.fwt_lower_page_bound,
    upper_bound = G.fwt_upper_page_bound,
  }
  assert(G.fwt_current_page > 0)
  assert(G.fwt_current_page <= profile_count / profiles_per_page)
  assert(G.focused_profile > 0)
  assert(G.focused_profile > (G.fwt_current_page-1) * profiles_per_page)
  assert(G.focused_profile <= (G.fwt_current_page) * profiles_per_page)
  assert(G.focused_profile <= profile_count)
  assert((G.fwt_lower_page_bound - 1) % profiles_per_page == 0)
  assert(G.fwt_upper_page_bound % profiles_per_page == 0)
  assert(profile_key_in_page_bounds(G.focused_profile))

  _make_sure_profiles_on_page_are_loaded()
end

function profile_key_in_page_bounds(key)
  return key >= G.fwt_lower_page_bound and key <= G.fwt_upper_page_bound 
end

function _make_sure_profiles_on_page_are_loaded()

  -- Might be worth unloading everything except the selected one first? you know, less shit in memory
  --print(G.fwt_current_page)
  for k=1,profile_count do
    -- If this profile is actuallyy on the page...
    if profile_key_in_page_bounds(k) then
      --print("Making this one real: "..k)
      if not G.PROFILES[k] then
        if love.filesystem.getInfo(k..'/'..'profile.jkr') then -- prefers the one in memory bc otherwise it overwrites itself with the old value right after you change the name 
          local file_contents = get_compressed(k..'/'..'profile.jkr')
          G.PROFILES[k] = STR_UNPACK(file_contents)
          --print("LOaded from file: "..k)
        else
          G.PROFILES[k] = {}
          --print("Set to default of nothing")
        end
      end
      if not G.PROFILES[k].name then
        G.PROFILES[k].name = 'P'..k
        --print("Set default name")
      end
      --print("Made this one real: "..G.PROFILES[k].name)
    end
  end
end



--------------- CALLBACKS ---------------

-- The function called by the button that opens the box :)
function G.FUNCS.profile_select(e)
  G.SETTINGS.paused = true
  G.focused_profile = G.SETTINGS.PROFILE

  G.FUNCS.overlay_menu{
    definition = G.UIDEF.fwt_profile_list(),
  }
end

-- Seems to be called when the box is opened and when the page is changed?
G.FUNCS.fwt_change_profile_list_page = function(args)
  -- Seems the rolling args are:
  -- from_val = from_val,
  --     to_val = to_val,
  --     from_key = from_key,
  --     to_key = to_key,
  --     cycle_config = e.config.ref_table
  ensure_or_set_current_page(args.to_key)
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
        definition =  G.UIDEF.fwt_profile_list_page(args.cycle_config.current_option),
        config = {offset = {x=0,y=0}, align = 'cm', parent = ch_list, colour=G.C.BLACK}
      }
      -- Update the description, too
      print("gggggggggggggggggggggggggggggggggggg"..G.focused_profile)
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
      assert(e.config.id > 0)
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

function G.FUNCS.deliberately_load_profile_wrapper(delete_prof_data)
  compress_and_save(selected_profile_filename, {G.focused_profile})
  G.FUNCS.load_profile(delete_prof_data)  -- I'm playing with fire here. what does delete_prof_data DO
end

G.FUNCS.can_load_profile_wrapper = function(e)
  G.FUNCS.can_load_profile(e)
  if e.config.button == 'load_profile' then
      e.config.button = 'deliberately_load_profile_wrapper'
  end
end






--------------- UI DEFINITIONS ---------------

-- The whole ass popup wooooah
function G.UIDEF.fwt_profile_list()
  local profile_pages = {}
  for i = 1, math.ceil(profile_count/profiles_per_page) do
    table.insert(profile_pages, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(profile_count/profiles_per_page)))
  end

  ensure_or_set_current_page()

  -- Not sure what this does
  -- Maybe it's what opens the box in the first place?
  G.E_MANAGER:add_event(
    Event({
      func = (function()
        G.FUNCS.fwt_change_profile_list_page{
          cycle_config = {
            current_option = G.fwt_current_page--+1 -- idk why the +1 is needed. there's a -1 in the foction that I also don't understand but it was in the source 
          }
        }
        return true
      end)
    })
  )

  local t = create_UIBox_generic_options({
    --back_id = 'fwt_profile_list', -- why would it need to be this??
    contents = {
      {
        n=G.UIT.C, 
        config={
          align = "cm", 
          padding = 0.0, 
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
            }
          },
        }
      },
    }
  })
  return t
end

-- The actual list part, like, the numbered rows, and their container
-- Said container is in its own container in create_UIBox_generic_options
function G.UIDEF.fwt_profile_list_page(_page)
  -- G.focused_profile = G.focused_profile or G.SETTINGS.profile or 1
  ensure_or_set_current_page(_page)
  
  -- Snapped is set to false on the first iteration, and true on every other.
  -- It can be true at first if the below check passes. idk what for
  -- turing it on for everything then off for everything didn't help
  local snapped = false 
  local fwt_profile_list = {}
  for k=1,profile_count do
    -- If this profile is actuallyy on the page...
    if profile_key_in_page_bounds(k) then
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
              profile_being_rendered.name and profile_being_rendered.name
              or profile_being_rendered.name
            },
            button = 'fwt_change_profile_description', -- TODO eyes
            minw = 4,
            scale = 0.4,
            minh = 0.6,

            -- vert is what makes it go on the left!!!! took me a while to get that
            -- ssee engline/ui.lua line 840 in the balatro source code
            chosen=G.focused_profile==k and 'vert' or false,
          }),

          -- Held the little radio buttons that show if a challenge is done.
          -- But they'll be nice if I want extra information later, maybe?
          -- I put it back tho because it's needed for alignment turns out
        {n=G.UIT.C, config={align = 'cm', padding = 0.05, minw = 0.6}, nodes = {
          -- {n=G.UIT.C, config={minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1, colour = G.C.BLUE}, nodes = {
          --   -- challenge_completed and {n=G.UIT.O, config={object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS["icons"], {x=1, y=0})}} or nil
          -- }},
        }},
      }}      
      snapped = true
    end
  end
  return {n=G.UIT.ROOT, config={align = "cm", padding = 0.1, colour=G.C.CLEAR}, nodes=fwt_profile_list}
end

-- https://stackoverflow.com/a/2705804
function table_length(tabletabletabletabletabletabletabletabletabletabletabletabletabletabletabletabletable)
  local count = 0
  for _ in pairs(tabletabletabletabletabletabletabletabletabletabletabletabletabletabletabletabletable) do count = count + 1 end
  return count
end


function G.UIDEF.profile_option(_profile)
  -- New

  -- So the text prompt for entering a name was super misaligned, not even in the box
  -- no idea why
  -- but if you put a second input after it, *that* one works
  -- and if you put a second input *before* it, the *original* works
  -- I am not paid
  print("DOING ITTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT".._profile)
  funny_fix = create_text_input({
    id='another_name', -- if its not given an id, they both default to the same thing, so funny fix activates when you click the other one
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
      t.config.w=0.0001
      t.config.scale=0
      t.config.text_scale=0
    end
    if t.nodes then
      for _, value in pairs(t.nodes) do
        shrink(value)
      end
    end
  end
  shrink(funny_fix)

  -- Original
  set_discover_tallies()
  G.focused_profile = _profile

  -- hiding this part bc it keeps crashing here and this stuff should be set earlier anyway
  -- local profile_data = get_compressed(G.focused_profile..'/'..'profile.jkr')
  -- if profile_data ~= nil then
  --   profile_data = STR_UNPACK(profile_data)
  --   profile_data.name = profile_data.name or ("P".._profile)
  -- end
  -- print("lllllllllllllllllllllllllllllllllllllllllllllllll")
  -- print(G.PROFILES[_profile])
  -- G.PROFILES[_profile].name = profile_data and profile_data.name or ''
  -- if G.PROFILES[G.focused_profile] then
  --   G.PROFILES[G.focused_profile].name = G.PROFILES[G.focused_profile].name or ("P"..G.focused_profile)
  -- end

  local lwidth, rwidth, scale = 1, 1, 1
  G.CHECK_PROFILE_DATA = nil
  -- In vanilla, it just checks if it even exists.
  -- right now, they get names right away, so it checks if they have *just* a name.
  profile_is_empty = not((not G.PROFILES[G.focused_profile]) or table_length(G.PROFILES[G.focused_profile]) >= 2)
  print(profile_is_empty)
  
  local t = {
    n=G.UIT.ROOT,
    config={align = "cm", colour = G.C.BLACK, minh = 8.82, minw = 11.5, r = 0.1},
    nodes=
    {
      {
        n=G.UIT.C,
        config={
          w=0,
          h=0,
        },
        nodes={
          funny_fix, -- new
        }
      },
      {
        n=G.UIT.R, 
        config={
          align = 'cm',
          padding = 0.1, 
          minh = 0.8,
        }, 
        nodes={
          (
            -- Prompt to enter or change name if it's their profile or an empty one
            (G.focused_profile == G.SETTINGS.profile) or profile_is_empty) and {
              n=G.UIT.R, 
              config={
                align = "cm",
                --colour=G.C.GREEN, -- was mpthing
              }, 
              nodes={
                create_text_input({
                  w = 4,
                  config={
                    align='cm',
                  },
                  align='cm',
                  max_length = 16, 
                  prompt_text = localize('k_enter_name'),
                  ref_table = G.PROFILES[G.focused_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
                  callback = function() 
                    print("------------------------------------")
                    print(G.focused_profile)
                    print(G.PROFILES[G.focused_profile].name)
                    local button_holder = G.OVERLAY_MENU:get_UIE_by_ID(G.focused_profile)
                    compress_and_save(selected_profile_filename, {G.focused_profile})
                    G:save_settings()
                    
                    G.FILE_HANDLER.force = true
                    G.UIDEF.fwt_profile_list_page(G.fwt_current_page)
                    G.FUNCS.fwt_change_profile_list_page({
                      to_key = G.fwt_current_page,
                      cycle_config = {
                        current_option = G.fwt_current_page
                      },
                    })
                  end
                }),
              }

            -- Name is unable to be edited
            } or {
              n=G.UIT.R, 
              config={
                align = 'cm',
                padding = 0.1, 
                minw = 4, 
                r = 0.1, 
                colour = G.C.UI.BACKGROUND_INACTIVE, 
                minh = 0.6
              }, 
              nodes={
                {
                  n=G.UIT.T, 
                  config={
                    text = G.PROFILES[G.focused_profile].name, 
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
                      button = "this doesn't matter lololololol boy it'll be really embarassing if this text shows up in an error message", 
                      shadow = true, 
                      focus_args = {nav = 'wide'}
                  }, 
                  nodes={{
                      n=G.UIT.T, 
                      config={
                          text = _profile == G.SETTINGS.profile and localize('b_current_profile') or (not profile_is_empty) and localize('b_load_profile') or localize('b_create_profile'), 
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














