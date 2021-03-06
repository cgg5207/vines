# encoding: UTF-8

require 'tmpdir'
require 'vines'
require 'ext/nokogiri'
require 'minitest/autorun'

class DiscoInfoTest < MiniTest::Unit::TestCase
  ALICE = Vines::User.new(:jid => 'alice@wonderland.lit/home')

  def setup
    @config = Vines::Config.new do
      host 'wonderland.lit' do
        storage(:fs) { dir Dir.tmpdir }
      end
    end
    @stream = MiniTest::Mock.new
    @stream.expect(:user, ALICE)
    @stream.expect(:config, @config)
  end

  def test_private_storage_disabled
    query = %q{<query xmlns="http://jabber.org/protocol/disco#info"/>}
    node = node(%Q{<iq id="42" to="wonderland.lit" type="get">#{query}</iq>})

    expected = node(%Q{
      <iq from="wonderland.lit" id="42" to="#{ALICE.jid}" type="result">
        <query xmlns="http://jabber.org/protocol/disco#info">
          <identity category="server" type="im"/>
          <feature var="http://jabber.org/protocol/disco#info"/>
          <feature var="http://jabber.org/protocol/disco#items"/>
          <feature var="urn:xmpp:ping"/>
          <feature var="vcard-temp"/>
          <feature var="jabber:iq:version"/>
        </query>
      </iq>
    }.strip.gsub(/\n|\s{2,}/, ''))

    @config.vhost('wonderland.lit').private_storage false
    @stream.expect(:write, nil, [expected])

    stanza = Vines::Stanza::Iq::DiscoInfo.new(node, @stream)
    stanza.process
    assert @stream.verify
  end

  def test_private_storage_enabled
    query = %q{<query xmlns="http://jabber.org/protocol/disco#info"/>}
    node = node(%Q{<iq id="42" to="wonderland.lit" type="get">#{query}</iq>})

    expected = node(%Q{
      <iq from="wonderland.lit" id="42" to="#{ALICE.jid}" type="result">
        <query xmlns="http://jabber.org/protocol/disco#info">
          <identity category="server" type="im"/>
          <feature var="http://jabber.org/protocol/disco#info"/>
          <feature var="http://jabber.org/protocol/disco#items"/>
          <feature var="urn:xmpp:ping"/>
          <feature var="vcard-temp"/>
          <feature var="jabber:iq:version"/>
          <feature var="jabber:iq:private"/>
        </query>
      </iq>
    }.strip.gsub(/\n|\s{2,}/, ''))

    @config.vhost('wonderland.lit').private_storage true
    @stream.expect(:write, nil, [expected])

    stanza = Vines::Stanza::Iq::DiscoInfo.new(node, @stream)
    stanza.process
    assert @stream.verify
  end

  private

  def node(xml)
    Nokogiri::XML(xml).root
  end
end
