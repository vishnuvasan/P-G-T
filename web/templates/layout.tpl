<!DOCTYPE html>
<html>
  <head>

    <!-- download the actual font -->
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,700,600,800' rel='stylesheet' type='text/css'>

    <link rel="stylesheet" href="/static/css/bootstrap.min.css">
    <link rel="stylesheet" href="/static/css/bootstrap-responsive.min.css">
    <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css">
    <link rel="stylesheet" href="/static/css/app.css">

    <!-- 
      <link rel='stylesheet' type='text/css' href='/static/css/pgtools.css' />
    -->

    <!-- Use original jquery -->
    <script src="http://code.jquery.com/jquery.js"></script>
    <script src="/static/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
    <script type="text/javascript" src="/static/js/app.js"></script>
    <script src='/static/js/jquery.stepy.js'> </script>

    <link href="http://www.headjump.de/stylesheets/arrowsandboxes.css" rel="stylesheet" type="text/css" />

    <script src='/static/js/pgtools.js'> </script>

    <title> PGTools </title>

  </head>
  <body>

    % for k in [ 'kind', 'is_config', 'is_tool', 'is_runs', 'is_workflow' ]:
      % if globals().get( k, None ) is None:
        % globals().update( { k: None } )
      % end
    % end


    <div class="container-fluid header-wrap">
      <div class="row-fluid">
        <div class="span12 header">
          <div class="span2">
            <a href='/'>
              <img src="/static/images/logo-left.png" class="logo" alt="">
            </a>
            <a href='/'>
              <img src="/static/images/logo-right.png" class="logo" alt="">
            </a>
          </div>
        
          <div class="span8 text-center"></div>
          <div class="span2 pull-right">
            <img src="/static/images/settings.png" class="pull-right" alt="">
          </div>

        </div>

        <div class="row-fluid">
          <div class="span12 bdd"></div>
        </div>
      </div>
    </div>
    <div class="container-fluid">
      <div class="row-fluid">
        <div class="span3 menu">
            <div class="accordion" id="accordion1">
              <div class="accordion-group">
                <div class="accordion-heading">
                  <a class="accordion-toggle {{ 'selected-black' if is_config else '' }}" data-toggle="collapse" data-parent="#accordion1" href="#collapseOne">
                    <img src="/static/images/configure_icon.png" alt="">Configure
                  </a>
                </div>

                <div id="collapseOne" class="accordion-body {{ 'collapse' if not is_config else '' }}">
                  <div class="accordion-inner">
                    <ul class="menu-inner">

                      <li class="{{ 'selected-yellow' if  kind == 'omssa' else '' }}" > 
                        <a href='/configure/omssa' > OMSSA </a>
                      </li>

                      <li class="{{ 'selected-yellow' if  kind == 'xtandem' else '' }}" > 
                        <a href='/configure/xtandem' > XTandem </a>
                      </li>

                      <li class="{{ 'selected-yellow' if  kind == 'msgf' else '' }}" > 
                        <a href='/configure/msgf' > MSGF+ </a>
                      </li>

                      <li class="{{ 'selected-yellow' if  kind == 'fdr' else '' }}" > 
                        <a href='/configure/fdr' > FDR </a>
                      </li>

                      <li class="{{ 'selected-yellow' if  kind == 'convert' else '' }}" > 
                        <a href='/configure/convert' > Convert </a>
                      </li>

                      <li  class="{{ 'selected-yellow' if  kind == 'circos' else '' }}" > 
                        <a href='/configure/circos' > Circos </a>
                      </li>

                      <li  class="{{ 'selected-yellow' if  kind == 'databases' else '' }}" > 
                        <a href='/configure/databases' > Genome Run Databases </a>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>

              <div class="accordion-group">
                <div class="accordion-heading">
                  <a class="accordion-toggle {{ 'selected-black' if is_tool else '' }}" data-toggle="collapse" data-parent="#accordion1" href="#collapseTwo">
                    <img src="/static/images/tools_icon.png">Tools
                  </a>
                </div>
                <div id="collapseTwo" class="accordion-body {{ 'collapse' if not is_tool else '' }}">
                  <div class="accordion-inner">
                    <ul class="menu-inner">

                      <li class="{{ 'selected-yellow' if  kind == 'decoy' else '' }}" >
                        <a href="/decoy"> Decoy </a>
                      </li>
                      <li  class="{{ 'selected-yellow' if  kind == 'translate' else '' }}" >
                        <a href="/translate"> Translate </a>
                      </li>
                      <li class="{{ 'selected-yellow' if  kind == 'annotate' else '' }}" >
                        <a href="/annotate"> Annotate </a>
                      </li>
                      <li class="{{ 'selected-yellow' if  kind == 'convert' else '' }}" >
                        <a href="/convert"> Convert </a>
                      </li>
                  </ul>
                  </div>
                </div>
              </div>



              <div class="accordion-group">
                <div class="accordion-heading">
                  <a class="accordion-toggle {{ 'selected-black' if is_workflow else '' }}" data-toggle="collapse" data-parent="#accordion1" href="#collapseThree">
                    <img src="/static/images/workflow_icon.png"> Workflows 
                  </a>
                </div>
                <div id="collapseThree" class="accordion-body {{ 'collapse' if not is_workflow else '' }}">
                  <div class="accordion-inner">
                    <ul class="menu-inner">

                      <li class="{{ 'selected-yellow' if  kind == 'complete_run' else '' }}" >
                        <a href="/new/proteome_run"> Proteome Run </a>
                      </li>

                      <li class="{{ 'selected-yellow' if  kind == 'genome_run' else '' }}" >
                        <a href="/new/genome_run"> Genome Run </a>
                      </li>

                    </ul>
                  </div>
                </div>
              </div>




              <div class="accordion-group">
                <div class="accordion-heading">
                  <a href='/runs' class="accordion-toggle {{ 'selected-black' if is_runs else '' }}">
                    <img src="/static/images/run_icon.png"> Runs 
                  </a>
                </div>
              </div>


            </div>
        </div>

        <div class="span9 rcontent">
          % include 
        </div>

      </div>
    </div>

    % include templates/includes/footer.tpl 

  </body>
</html>
