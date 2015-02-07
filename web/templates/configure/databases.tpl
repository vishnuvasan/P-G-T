  % include templates/includes/error.tpl
  <form method='POST'>


    % include templates/includes/input.tpl path=True, label="UTR", name="utr", value=config['databases'].get( 'utr', '' ), help='Filesystem path for UTR Database'

    % include templates/includes/input.tpl path=True, label="Non-Code", name="noncode", value=config['databases'].get( 'noncode', '' ), help='Filesystem path for Non-Code Database'

    % include templates/includes/input.tpl path=True, label="Splice", name="splice", value=config['databases'].get( 'splice', '' ), help='Filesystem path for Splice Database'

    % include templates/includes/input.tpl path=True, label="Pseudo-Gene", name="pseudogene", value=config['databases'].get( 'pseudogene', '' ), help='Filesystem path for Pseudogene Database'

    % include templates/includes/input.tpl path=True, label="Six Frame", name="6frame", value=config['databases'].get( '6frame', '' ), help='Filesystem path for Sixframe Database'

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True
