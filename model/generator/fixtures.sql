

insert into services(root_id, name, summary, content)
  values (
    -3,
    'The Mystique',
    'Curiousities of the otherworld',
    xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h1 itempath="service[name]">The Mystique</h1>
      <p itempath="service[summary]">Curiousities of the otherworld</p>
    </section>')
  );

insert into services(root_id, name, summary, content)
  values (
    -2,
    'Origin',
    'A template for the app',
    xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h1 itempath="service[name]">Origin</h1>
      <p itempath="service[summary]">A template for the app</p>
    </section>')
  );

insert into categories(service_id, root_id, name, summary, content, articles_content)
  values (
    -3, 
    -1666,
    'Places I''ve been to', 
    'From depths of cosmic horror to lifeless plains of ancient gods.',
    xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
      <h1 itempath="category[name]">Places I''ve been to</h1>
      <p itempath="category[summary]">From depths of cosmic horror to lifeless plains of ancient gods.</p>
      <p>Sometimes I go to church too</p>
    </section>
    <section class="forced"><x-div class="kx foreground"><svg /></x-div>
      <x-div class="kx foreground"><svg /></x-div>
      <h3>My descent into madness</h3>
      <p>The story is long to tell and it goes on in this section. My whole life since childhood till this day I was collecting scrapes and bits of mysteries around me.</p>

    </section>'::xml, 'categories', 'places_ive_been_to', 'content'),
    xmlarticleroot('
    <section class="forced position-2"><x-div class="kx foreground"><svg /></x-div>
      <h3>It''s dangerous to go alone</h3>
      <p>Take this. The knowledge presented here is hidden from the eye of regular fellow, and that is for a good reason.</p>
    </section>'::xml, 'categories', 'places_ive_been_to', 'articles_content'));

insert into articles(service_id, root_id, category_id, title, summary, content)
values (
  -3, 
  -1667,
  -1666,
  'Caves of unbeing', 
  'The time has stalled in these eternal ruins that seen original inhabitants of Earth',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="article[title]">Caves of unbeing</h1>
    <p itempath="article[summary]">The time has stalled in these eternal ruins that seen original inhabitants of Earth.</p>
    <p>Tread safely, as the unfriendly dunes only open up once per century and will devour uncaring adventurer.</p></section>
  '::xml, 'articles', 'caves_of_unbeing'));


insert into articles(service_id, root_id, category_id, title, summary, content)
values (
  -3,
  -1668,
  -1666,
  'Dunwich swamps', 
  'A den of witchraft, forsaken by the nature itself is a pulsating heart of evil',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
   <h1 itempath="article[title]">Dunwich swamps</h1>
   <p itempath="article[summary]">A den of witchraft, forsaken by the nature itself is a pulsating heart of evil.</p>
   <p>Dunwich is surrounded undated ceremonial burials. Each spring the unholy filth floods the streets of the town.</p>
   </section>'::xml, 'articles', 'dunwich_samps'));

insert into articles(service_id, root_id, category_id, title, summary, content)
values (
  -3,
  -1669,
  -1666,
  'Fourth dimension', 
  'A pocket of ungodly geometry is accessible to a bearer of the skeleton key.',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
   <h1 itempath="article[title]">Fourth dimension</h1>
   <p itempath="article[summary]">A pocket of ungodly geometry is accessible to a bearer of the skeleton key.</p>
   <p>Al-Khazred noted that human mind is incapable of grasping depth of eternity and is an easy prey for the mind Flayers.</p>
   </section>'::xml, 'articles', 'fourth_dimension'));


insert into categories(service_id, root_id, name, summary, content)
values (
  -3,
  -1766,
  'Things I wrote', 
  'Forbidden mysteries of unhuman lore, unseen manuscripts of unknown civilizations.',
  xmlarticleroot('
    <section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="category[name]">Things I wrote</h1>
    <p itempath="category[summary]">Forbidden mysteries of unhuman lore, unseen manuscripts of unknown civilizations.</p>
    <p>There is no way back to sanity.</p>
  </section>'::xml, 'categories', 'things_i_wrote'));


insert into articles(service_id, root_id, category_id, title, summary, content)
values (
  -3, 
  -1767,
  -1766,
  'Necronomicon digest', 
  'Ancient writings hold numerous secrets. Millenias passed since old gods, and the understanding of subjects is long lost.',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="article[title]">Necronomicon digest</h1>
    <p itempath="article[summary]">Ancient writings hold numerous secrets. Millenias passed since old gods, and the understanding of subjects is long lost.</p>
    <p>An attempt at rediscovering and evolving work of known mystical scholars like Aesoteph IV and the Poe twins.</p></section>
  '::xml, 'articles', 'necronomicon_digest'));



insert into articles(service_id, root_id, category_id, title, summary, content)
values (
  -3, 
  -1768,
  -1766,
  'Kerangasem investigation', 
  'Villages of a small fishing set large jungle forest on fire. The fire kills thousands.',
  xmlarticleroot('<section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="article[title]">Kerangasem investigation</h1>
    <p itempath="article[summary]">Villages of a small fishing set large jungle forest on fire. The fire kills thousands.</p>
    <p>Investigation led by local government halted as villages would not cooperate. One of the elders tells the fire is the only way to stop the spirits of corruption.</p></section>
  '::xml, 'articles', 'sunset_shriek'));


insert into categories(service_id, root_id, name, summary, content)
values (
  -3,
  -1768,
  'Things I dont know', 
  'Everybody does not know something. Just like any other mortal, I can not see beneath the veil of ignorance.',
  xmlarticleroot('
    <section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="category[name]">Things I dont know</h1>
    <p itempath="category[summary]">Everybody does not know something. I dont know what I dont know, personally.</p>
  </section>'::xml, 'categories', 'things_i_dont_know'));


insert into inquiries(service_id, root_id, name, summary, content)
values (
  -3,
  -1766,
  'How to cope with cosmic horror?', 
  'The first step to maturation of human psyque is to acknowledge human insignificance at the scale of universe.',
  xmlarticleroot('
    <section><x-div class="kx foreground"><svg /></x-div>
    <h1 itempath="inquiry[name]">Things I dont know</h1>
    <p itempath="inquiry[summary]">Everybody does not know something. I dont know what I dont know, personally.</p>
  </section>'::xml, 'categories', 'things_i_wrote'));