#!/usr/bin/env/ruby
require 'rubygems'
require 'erb'
require 'roda'
require 'models'
require 'rack/protection'

class FormeDemo < Roda
  use Rack::Static, :urls=>%w'/css', :root=>'public'
  use Rack::Protection, :except=>[:remote_token, :session_hijacking]

  plugin :forme
  plugin :h
  plugin :static_path_info

  attr_reader :form_attr
  attr_reader :subform_opts

  def form_opts
    return @form_opts if @form_opts
    @form_opts = @form_opts_base || {}
    @form_opts[:one] ||= {}
    @form_opts[:many] ||= {}
    @form_opts[:date] ||= {}
    @form_opts
  end

  def demo(t, opts={})
    @templ = t
    @form_attr = DEMO_MODE ? {:onsubmit=>'return false'} : {:action=>"/#{t.to_s.split('_').first}"}
    view(t, opts)
  end

  route do |r|
    r.get do
      r.is '' do
        @page_title = 'Forme Demo Site'
        view :index
      end

      r.on 'album' do
        r.on 'basic' do
          r.is 'default' do
            @page_title = 'Album Basic - Default'
            @css = "form label { display: block; }"
            demo :album_basic
          end

          r.is 'explicit' do
            @page_title = 'Album Basic - Explicit Labels'
            @form_opts_base = {:labeler=>:explicit, :wrapper=>:div}
            @css = <<-END
              label, input, select { display: block; float: left }
              label { min-width: 150px; }
              form div { padding: 5px; clear: both; }
            END
            demo :album_basic
          end

          r.is 'table' do
            @page_title = 'Album Basic - Table'
            @form_opts_base = {:labeler=>:explicit, :wrapper=>:trtd, :inputs_wrapper=>:table}
            demo :album_basic
          end

          r.is 'list' do
            @page_title = 'Album Basic - List'
            @form_opts_base = {:wrapper=>:li, :inputs_wrapper=>:ol}
            @css = "ol, li {list-style-type: none;}"
            demo :album_basic
          end

          r.is 'date' do
            @page_title = 'Album Basic - Date Multiple Select Boxes'
            @form_opts_base = {:date=>{:as=>:select}, :labeler=>:explicit, :wrapper=>:trtd, :inputs_wrapper=>:table}
            demo :album_basic
          end

          r.is 'alt_assoc' do
            @page_title = 'Album Basic - Association Radios/Checkboxes'
            @form_opts_base = {:wrapper=>:li, :inputs_wrapper=>:ol, :many=>{:as=>:checkbox}, :one=>{:as=>:radio}}
            @css = "ol, li {list-style-type: none;}"
            demo :album_basic
          end

          r.is 'readonly' do
            @page_title = 'Album Basic - Read Only'
            @form_opts_base = {:wrapper=>:li, :inputs_wrapper=>:ol, :formatter=>:readonly}
            @css = "ol, li {list-style-type: none;}"
            demo :album_basic
          end

          r.is 'text' do
            @page_title = 'Album Basic - Plain Text'
            @form_opts_base = {:serializer=>:text}
            response['Content-Type'] = 'text/plain'
            demo :album_basic, :layout=>false
          end
        end

        r.is 'nested' do
          @page_title = 'Single Level Nesting'
          @css = "form label { display: block; }"
          @subform_opts = {}
          demo :album_nested
        end

        r.is 'grid' do
          @page_title = 'Single Level Grid'
          @subform_opts = {:grid=>true}
          demo :album_nested
        end
      end

      r.on 'artist' do
        r.is 'nested' do
          @page_title = 'Multiple Level Nesting'
          @css = "form label { display: block; }"
          @subform_opts = {}
          demo :artist_nested
        end

        r.is 'grid' do
          @page_title = 'Multiple Level Grid'
          @css = '.integer input, .float input {width: 40px;}'
          @subform_opts = {:grid=>true}
          demo :artist_grid
        end
      end
    end

    unless ENV['DATABASE_URL']
      r.post do
        r.is 'album' do
          Album.last.update(r['album'])
          r.redirect r.referrer
        end

        r.is 'artist' do
          Artist.last.update(r['artist'])
          r.redirect r.referrer
        end
      end
    end
  end
end
