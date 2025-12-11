# frozen_string_literal: true

module Lightpanda
  module Capybara
    class Node < ::Capybara::Driver::Node
      attr_reader :selector_info

      def initialize(driver, native, _index)
        super(driver, native)

        @selector_info = native # { selector: "h1", index: 0 }
      end

      def text
        evaluate_on("this.textContent")
      end

      def visible_text
        evaluate_on("this.innerText")
      end

      def [](name)
        evaluate_on("this.getAttribute(#{name.to_s.inspect})")
      end

      def value
        evaluate_on(<<~JS)
          (function(el) {
            if (el.tagName === 'SELECT' && el.multiple) {
              return Array.from(el.selectedOptions).map(o => o.value);
            }
            return el.value;
          })(this)
        JS
      end

      def style(styles)
        styles.each_with_object({}) do |style, result|
          result[style] = evaluate_on("window.getComputedStyle(this).#{style}")
        end
      end

      def click(_keys = [], **_options)
        evaluate_on("this.click()")
      end

      def right_click(_keys = [], **_options)
        evaluate_on(<<~JS)
          this.dispatchEvent(new MouseEvent('contextmenu', {bubbles: true, cancelable: true}))
        JS
      end

      def double_click(_keys = [], **_options)
        evaluate_on(<<~JS)
          this.dispatchEvent(new MouseEvent('dblclick', {bubbles: true, cancelable: true}))
        JS
      end

      def hover
        evaluate_on(<<~JS)
          this.dispatchEvent(new MouseEvent('mouseover', {bubbles: true, cancelable: true}))
        JS
      end

      def set(value, **_options)
        if tag_name == "input"
          type = self["type"]
          case type
          when "checkbox", "radio"
            if value
              evaluate_on("this.checked = true; this.dispatchEvent(new Event('change', {bubbles: true}))")
            else
              evaluate_on("this.checked = false; this.dispatchEvent(new Event('change', {bubbles: true}))")
            end
          when "file"
            raise NotImplementedError, "File inputs need special handling via CDP. File uploads not yet supported"
          else
            set_text_value(value)
          end
        elsif tag_name == "textarea"
          set_text_value(value)
        elsif self["contenteditable"]
          evaluate_on("this.innerHTML = #{value.to_s.inspect}")
        end
      end

      def select_option
        evaluate_on(<<~JS)
          this.selected = true;
          var event = new Event('change', {bubbles: true});
          this.parentElement.dispatchEvent(event);
        JS
      end

      def unselect_option
        select = find_xpath("./ancestor::select")[0]

        if select && !select["multiple"]
          raise ::Capybara::UnselectNotAllowed, "Cannot unselect option from single select"
        end

        evaluate_on(<<~JS)
          this.selected = false;
          var event = new Event('change', {bubbles: true});
          this.parentElement.dispatchEvent(event);
        JS
      end

      def send_keys(*args)
        args.each do |key|
          next unless key.is_a?(String)

          evaluate_on(<<~JS)
            this.focus();
            this.value += #{key.inspect};
            this.dispatchEvent(new Event('input', {bubbles: true}));
          JS
        end
      end

      def tag_name
        evaluate_on("this.tagName.toLowerCase()")
      end

      def visible?
        selector = @selector_info[:selector]
        index = @selector_info[:index]

        js = <<~JS
          (function() {
            var el = document.querySelectorAll(#{selector.inspect})[#{index}];
            if (!el) return false;
            var style = window.getComputedStyle(el);
            var isVisible = style.display !== 'none' &&
                   style.visibility !== 'hidden' &&
                   el.offsetParent !== null;
            return isVisible;
          })()
        JS

        driver.browser.evaluate(js)
      end

      def checked?
        evaluate_on("this.checked")
      end

      def selected?
        evaluate_on("this.selected")
      end

      def disabled?
        evaluate_on("this.disabled")
      end

      def readonly?
        evaluate_on("this.readOnly")
      end

      def multiple?
        evaluate_on("this.multiple")
      end

      def path
        evaluate_on(<<~JS)
          (function(el) {
            if (!el) return '';
            var path = [];

            while (el && el.nodeType === Node.ELEMENT_NODE) {
              var selector = el.nodeName.toLowerCase();
              if (el.id) {
                selector += '#' + el.id;
                path.unshift(selector);
                break;
              } else {
                var sibling = el;
                var nth = 1;
                while (sibling = sibling.previousElementSibling) {
                  if (sibling.nodeName.toLowerCase() === selector) nth++;
                }
                if (nth > 1) selector += ':nth-of-type(' + nth + ')';
              }
              path.unshift(selector);
              el = el.parentNode;
            }
            return path.join(' > ');
          })(this)
        JS
      end

      def find_xpath(selector)
        driver.find_xpath(selector)
      end

      def find_css(selector)
        count = evaluate_on("this.querySelectorAll(#{selector.inspect}).length")

        return [] if count.nil? || count.zero?

        (0...count).map do |idx|
          child_selector = "#{element_selector} #{selector}"

          Node.new(driver, { selector: child_selector, index: idx }, idx)
        end
      end

      def ==(other)
        other.is_a?(self.class) && selector_info == other.selector_info
      end

      private

      def element_selector
        if @selector_info.is_a?(Hash)
          selector = @selector_info[:selector]
          index = @selector_info[:index]

          index.positive? ? "#{selector}:nth-of-type(#{index + 1})" : selector
        else
          "*"
        end
      end

      def set_text_value(value) # rubocop:disable Naming/AccessorMethodName
        evaluate_on(<<~JS)
          this.focus();
          this.value = #{value.to_s.inspect};
          this.dispatchEvent(new Event('input', {bubbles: true}));
          this.dispatchEvent(new Event('change', {bubbles: true}));
        JS
      end

      def evaluate_on(expression)
        selector = @selector_info[:selector]
        index = @selector_info[:index]

        expr = expression.strip
        expr = "return #{expr}" unless expr.start_with?("return ") || expr.include?("\n")

        full_expression = <<~JS
          (function() {
            var elements = document.querySelectorAll(#{selector.inspect});
            var el = elements[#{index}];
            if (!el) return null;
            return (function() { #{expr} }).call(el);
          })()
        JS

        driver.browser.evaluate(full_expression)
      end
    end
  end
end
