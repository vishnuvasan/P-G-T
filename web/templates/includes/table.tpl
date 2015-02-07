<table class='table table-striped table-bordered'>
  % for row in table:
    <tr>
      % for i in row:
        <td>
          % if i.startswith( 'http://'):
            <a target='_blank' href='{{ i }}'> {{ i }} </a>
          % else:
            {{! i.replace( "\n", "<br />" ) }} 
          % end
        </td>
      % end
    </tr>
  % end
</table>
