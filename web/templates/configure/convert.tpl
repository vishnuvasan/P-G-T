  <h1> </h1>

  % include templates/includes/error.tpl

  <form method='POST'>


    % include templates/includes/input.tpl path=True, label="Path for OpenMS Convert", name="convert_path", value=config[kind].get( 'command', ''), help='Filesystem path for OpenMS Convert'

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True
