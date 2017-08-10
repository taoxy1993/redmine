module CategorysHelper

=begin
导出部门信息
=end
  def department_export_to_csv(departments)
    csv_string = FCSV.generate do |csv|
      csv << ["\xEF\xBB\xBF部门","部门经理"]
      departments.each do |department|
        csv << [department.dep_name, find_project_manager(department.dep_id, "部门经理")]
      end
    end
    csv_string
  end

=begin
导出产品信息
=end
  def product_export_to_csv(products)
    csv_string = FCSV.generate do |csv|
      csv << ["\xEF\xBB\xBF产品","项目","项目经理"]
      products.each do |product|
        csv << [product.product_name, product.proj_name, find_project_manager(product.proj_id, "项目经理")]
      end
    end
    csv_string
  end

=begin
导出项目信息
=end
  def project_export_to_csv(projects)
    csv_string = FCSV.generate do |csv|
      csv << ["\xEF\xBB\xBF项目","项目经理"]
      projects.each do |project|
        csv << [project.proj_name, find_project_manager(project.proj_id, "项目经理")]
      end
    end
    csv_string
  end

end