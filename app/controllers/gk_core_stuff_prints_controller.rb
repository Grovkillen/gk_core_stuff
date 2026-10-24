# frozen_string_literal: true

# export_log: a print asked for in the browser (the script on every page tells when printing starts); written as the
# event printed on what the page shows (GkCoreStuff::ExportLog.printed!). Only for one who is logged in; answers
# 204 whatever happened, so the page never waits on it.
class GkCoreStuffPrintsController < ApplicationController
  before_action :require_login

  def create
    GkCoreStuff::ExportLog.printed!(params[:path].to_s, request)
    head :no_content
  end
end
