  <h1> </h1>

  % include templates/includes/error.tpl

  <form method='POST'>

    % include templates/includes/input.tpl path=True, label="Path for Circos", name="circos_path", value=config[ kind ].get( 'command', '' ), help='Filesystem path for Circos'

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True
