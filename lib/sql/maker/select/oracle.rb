require 'sql/maker/select'

class SQL::Maker::Select::Oracle < SQL::Maker::Select
  ## Oracle doesn't have the LIMIT clause.
  def as_limit
    return ''
  end

  ## Override as_sql to emulate the LIMIT clause.
  def as_sql
    limit  = self.limit
    offset = self.offset

    if limit && offset
      self.add_select( "ROW_NUMBER() OVER (ORDER BY 1) R" )
    end

    sql = super

    if limit
      sql = "SELECT * FROM ( #{sql} ) WHERE "
      if offset
        sql = sql + " R BETWEEN #{offset} + 1 AND #{limit} + #{offset}"
      else
        sql = sql + " rownum <= #{limit}"
      end
    end
    return sql
  end
end
