<div class='row'>
  <div class="span2 bs-docs-sidebar">
    <ul class="nav nav-list bs-docs-sidenav nav-stacked affix">
      % for _wf in wf:

        % if current_workflow.lower() in _wf.lower():
          <li class='active'>
        % else:
          <li>
        % end

          <a href='/workflow/{{ _wf[ _wf.index( '_' ) + 1 : ] }}'> 
            <i class='icon-chevron-right'> </i>
            {{ _wf[ _wf.index( '_' ) + 1 : ].capitalize() }}
          </a>
        </li>
      % end
    </ul>
  </div>

  <div class='span9 offset1'>
    <div class='hero-unit'>
      <h2> {{ current_workflow }} </h2>

      <pre class="arrows-and-boxes">
        () (o{omssa-node}:ommsa >[mg])||
        ({start-node}:Start >[o,xt,m]) (xt{xtandem-node}:xtandem) >  (fdr{fdr-node}:FDR) > (mg{pepmerge-node}:Merge) > ({group-node}:Group) > (dd{done-node}:Done)||
        ()(m{msgf-node}:mfgdb >[mg]) 
      </pre>

      <div class='pull-right'>
        <a href='/workflow/{{ current_workflow }}/start' class='btn btn-primary btn-large'> Start </a>
      </div>

    </div>


  </div>
</div>
%rebase templates/layout
