insert into categories(root_id, name, summary, content, articles_content)
  values (
    666,
    'Places I''ve been to', 
    'From depths of cosmic horror to lifeless plains of ancient gods.',
    xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h1>Places I''ve been to</h1>
      <p>From depths of cosmic horror to lifeless plains of ancient gods.</p>
      <p>Sometimes I go to church too</p>
    </section>
    <section class="forced"><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h3>My descent into madness</h3>
      <p>The story is long to tell and it goes on in this section. My whole life since childhood till this day I was collecting scrapes and bits of mysteries around me.</p>

    </section>'::xml, 'categories', 'places_ive_been_to', 'content'),
    xmlarticleroot('
    <section class="forced position-2"><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h3>It''s dangerous to go alone</h3>
      <p>Take this. The knowledge presented here is hidden from the eye of regular fellow, and that is for a good reason.</p>
    </section>'::xml, 'categories', 'places_ive_been_to', 'articles_content'));

insert into articles(root_id, category_id, title, summary, content)
values (
  667,
  666,
  'Caves of unbeing', 
  'The time has stalled in these eternal ruins that seen original inhabitants of Earth',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
    <h1>Caves of unbeing</h1>
    <p>The time has stalled in these eternal ruins that seen original inhabitants of Earth.</p>
    <p>Tread safely, as the unfriendly dunes only open up once per century and will devour uncaring adventurer.</p></section>
  '::xml, 'articles', 'caves_of_unbeing'));


insert into articles(root_id, category_id, title, summary, content)
values (
  668,
  666,
  'Dunwich swamps', 
  'A den of witchraft, forsaken by the nature itself is a pulsating heart of evil',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
   <h1>Dunwich swamps</h1>
   <p>A den of witchraft, forsaken by the nature itself is a pulsating heart of evil.</p>
   <p>Dunwich is surrounded undated ceremonial burials. Each spring the unholy filth floods the streets of the town.</p>
   </section>'::xml, 'articles', 'dunwich_samps'));

insert into articles(root_id, category_id, title, summary, content)
values (
  669,
  666,
  'Fourth dimension', 
  'A pocket of ungodly geometry is accessible to a bearer of the skeleton key.',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
   <h1>Fourth dimension</h1>
   <p>A pocket of ungodly geometry is accessible to a bearer of the skeleton key.</p>
   <p>Al-Khazred noted that human mind is incapable of grasping depth of eternity and is an easy prey for the mind Flayers.</p>
   </section>'::xml, 'articles', 'fourth_dimension'));



insert into categories(root_id, name, summary, content)
values (
  766,
  'Things I wrote', 
  'Forbidden mysteries of unhuman lore, unseen manuscripts of unknown civilizations.',
  xmlarticleroot('
    <section><x-div class="kx foreground"><svg /></x-div>
    <h1>Things I wrote</h1>
    <p>Forbidden mysteries of unhuman lore, unseen manuscripts of unknown civilizations.</p>
    <p>There is no way back to sanity.</p>
  </section>'::xml, 'categories', 'things_i_wrote'));

