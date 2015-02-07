  % include templates/includes/error.tpl
  <h1> </h1>

  <form method='POST'>

    <div class="control-group">
      <label for="" class="control-label"> Enable XTandem! </label>
      <div class="controls">
        <div class="slide-checkbox">  
          <input type="checkbox" value="on" id="checkbox1" name="xtandem_enabled" class="on-off" {{config[kind]['enabled']}}/>
          <label for="checkbox1"></label>
        </div>
      </div>
    </div>

    % include templates/includes/input.tpl path=True, label="Path", name="xtandem_path", value=config[kind]['path'], help='Filesystem path for XTandem!'

    % include templates/includes/submit.tpl


  </form>

%rebase templates/layout kind=kind, is_config=True

